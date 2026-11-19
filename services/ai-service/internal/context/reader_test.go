package context

import (
	"context"
	"strings"
	"testing"
)

func TestBuildSystemPromptIncludesSafeActionBoundaryAndCustomPrompt(t *testing.T) {
	prompt := BuildSystemPrompt(context.Background(), nil, "DRIVER", "", "Ringkas daftar belanja")
	if !strings.Contains(prompt, "SAFE ACTION BOUNDARY") {
		t.Fatal("expected Safe Action Boundary rules in system prompt")
	}
	if !strings.Contains(prompt, "Ringkas daftar belanja") {
		t.Fatal("expected custom prompt to be appended")
	}
}

