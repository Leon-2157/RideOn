package router

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"time"
)

const FallbackInactiveMessage = "Halo! Asisten layanan pintar RideOn saat ini sedang belum diaktifkan oleh Admin. Silakan hubungi tim bantuan melalui menu Tiket Bantuan atau coba beberapa saat lagi."

type ProviderConfig struct {
	ID            string
	DisplayName   string
	AdapterType   string // "openai_compatible" or "gemini_native"
	BaseURL       string
	APIKey        string
	ModelName     string
	SystemPrompt  string
	Temperature   float64
	MaxTokens     int
	PriorityOrder int
	IsActive      bool
}

type GenerateResult struct {
	Reply        string
	ProviderUsed string
	LatencyMs    int
	Simulated    bool
}

type InvokerFunc func(ctx context.Context, p ProviderConfig, userMessage string) (string, error)

// FilterAndSortActive returns only active providers with a non-empty APIKey,
// sorted by PriorityOrder ascending.
func FilterAndSortActive(providers []ProviderConfig) []ProviderConfig {
	var active []ProviderConfig
	for _, p := range providers {
		if p.IsActive && strings.TrimSpace(p.APIKey) != "" {
			active = append(active, p)
		}
	}
	sort.SliceStable(active, func(i, j int) bool {
		return active[i].PriorityOrder < active[j].PriorityOrder
	})
	return active
}

// RouteWithFailover attempts active providers in ascending PriorityOrder.
// If no active provider is configured, it returns FallbackInactiveMessage without error.
func RouteWithFailover(ctx context.Context, providers []ProviderConfig, userMessage string, invoke InvokerFunc) (GenerateResult, error) {
	candidates := FilterAndSortActive(providers)
	if len(candidates) == 0 {
		return GenerateResult{
			Reply:        FallbackInactiveMessage,
			ProviderUsed: "fallback_inactive",
			LatencyMs:    0,
			Simulated:    true,
		}, nil
	}

	if invoke == nil {
		invoke = DefaultHTTPInvoker
	}

	var errs []string
	for _, p := range candidates {
		start := time.Now()
		reply, err := invoke(ctx, p, userMessage)
		elapsed := int(time.Since(start).Milliseconds())
		if err == nil && strings.TrimSpace(reply) != "" {
			return GenerateResult{
				Reply:        strings.TrimSpace(reply),
				ProviderUsed: p.DisplayName,
				LatencyMs:    elapsed,
				Simulated:    false,
			}, nil
		}
		if err != nil {
			errs = append(errs, fmt.Sprintf("%s: %v", p.DisplayName, err))
		} else {
			errs = append(errs, fmt.Sprintf("%s: empty reply", p.DisplayName))
		}
	}

	return GenerateResult{}, fmt.Errorf("all active providers failed (%s)", strings.Join(errs, "; "))
}

// DefaultHTTPInvoker dispatches the prompt using either the "openai_compatible"
// or "gemini_native" protocol adapter.
func DefaultHTTPInvoker(ctx context.Context, p ProviderConfig, userMessage string) (string, error) {
	client := &http.Client{Timeout: 25 * time.Second}
	sysPrompt := strings.TrimSpace(p.SystemPrompt)
	if sysPrompt == "" {
		sysPrompt = "Anda adalah asisten layanan ekosistem RideOn Lhokseumawe & Aceh Utara. Jawab dengan sopan, ringkas, dan jelas dalam Bahasa Indonesia."
	}

	switch p.AdapterType {
	case "openai_compatible":
		return callStandardV1(ctx, client, p, sysPrompt, userMessage)
	case "gemini_native":
		return callNativeGen(ctx, client, p, sysPrompt, userMessage)
	default:
		return "", fmt.Errorf("unsupported adapter_type: %s", p.AdapterType)
	}
}

func callStandardV1(ctx context.Context, client *http.Client, p ProviderConfig, sysPrompt, userMessage string) (string, error) {
	endpoint := strings.TrimRight(strings.TrimSpace(p.BaseURL), "/") + "/chat/completions"
	maxTok := p.MaxTokens
	if maxTok <= 0 {
		maxTok = 1024
	}
	payload := map[string]any{
		"model": p.ModelName,
		"messages": []map[string]string{
			{"role": "system", "content": sysPrompt},
			{"role": "user", "content": userMessage},
		},
		"temperature": p.Temperature,
		"max_tokens":  maxTok,
	}
	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(bodyBytes))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+strings.TrimSpace(p.APIKey))

	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	respBytes, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(respBytes)))
	}

	var parsed struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(respBytes, &parsed); err != nil {
		return "", err
	}
	if len(parsed.Choices) == 0 || strings.TrimSpace(parsed.Choices[0].Message.Content) == "" {
		return "", errors.New("no content in response choices")
	}
	return parsed.Choices[0].Message.Content, nil
}

func callNativeGen(ctx context.Context, client *http.Client, p ProviderConfig, sysPrompt, userMessage string) (string, error) {
	base := strings.TrimRight(strings.TrimSpace(p.BaseURL), "/")
	endpoint := fmt.Sprintf("%s/models/%s:generateContent?key=%s",
		base,
		url.PathEscape(strings.TrimSpace(p.ModelName)),
		url.QueryEscape(strings.TrimSpace(p.APIKey)),
	)
	maxTok := p.MaxTokens
	if maxTok <= 0 {
		maxTok = 1024
	}
	payload := map[string]any{
		"systemInstruction": map[string]any{
			"parts": []map[string]string{
				{"text": sysPrompt},
			},
		},
		"contents": []map[string]any{
			{
				"role": "user",
				"parts": []map[string]string{
					{"text": userMessage},
				},
			},
		},
		"generationConfig": map[string]any{
			"temperature":     p.Temperature,
			"maxOutputTokens": maxTok,
		},
	}
	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(bodyBytes))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	respBytes, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(respBytes)))
	}

	var parsed struct {
		Candidates []struct {
			Content struct {
				Parts []struct {
					Text string `json:"text"`
				} `json:"parts"`
			} `json:"content"`
		} `json:"candidates"`
	}
	if err := json.Unmarshal(respBytes, &parsed); err != nil {
		return "", err
	}
	if len(parsed.Candidates) == 0 || len(parsed.Candidates[0].Content.Parts) == 0 {
		return "", errors.New("no candidates in response")
	}
	return parsed.Candidates[0].Content.Parts[0].Text, nil
}

