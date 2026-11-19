"use client";

import { useEffect, useMemo } from "react";
import L from "leaflet";
import { MapContainer, Marker, Popup, TileLayer, useMap } from "react-leaflet";

type MapPoint = {
  id: string;
  name: string;
  kind: "driver" | "store";
  city: string;
  status: string;
  latitude: number;
  longitude: number;
  detail: string;
};

export default function OpenStreetMap({ points, selectedId, onSelect }: { points: MapPoint[]; selectedId: string | null; onSelect: (id: string) => void }) {
  const selected = points.find((point) => point.id === selectedId) ?? null;
  return <MapContainer className="osm-map" center={[5.215, 97.055]} zoom={10} minZoom={8} maxZoom={16} scrollWheelZoom zoomControl>
    <TileLayer url="https://tile.openstreetmap.org/{z}/{x}/{y}.png" attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors' />
    {points.map((point) => <LocationMarker key={point.id} point={point} selected={selected?.id === point.id} onSelect={onSelect} />)}
    {selected && <MapFocus point={selected} />}
  </MapContainer>;
}

function LocationMarker({ point, selected, onSelect }: { point: MapPoint; selected: boolean; onSelect: (id: string) => void }) {
  const icon = useMemo(() => L.divIcon({
    className: "rideon-marker-shell",
    html: `<span class="rideon-marker ${point.kind === "driver" ? "rideon-marker-driver" : "rideon-marker-store"} ${selected ? "rideon-marker-selected" : ""}"><span>${point.kind === "driver" ? "D" : "T"}</span></span>`,
    iconSize: [34, 38],
    iconAnchor: [17, 34],
    popupAnchor: [0, -31],
  }), [point.kind, selected]);

  return <Marker position={[point.latitude, point.longitude]} icon={icon} title={`${point.name}, ${point.city}`} alt={`${point.kind === "driver" ? "Driver" : "Toko"} ${point.name}`} eventHandlers={{ click: () => onSelect(point.id) }}>
    <Popup><div className="osm-popup"><strong>{point.name}</strong><span>{point.kind === "driver" ? "Driver" : "Toko"} · {point.city}</span><small>{point.status} · Live Database</small><p>{point.detail}</p></div></Popup>
  </Marker>;
}

function MapFocus({ point }: { point: MapPoint }) {
  const map = useMap();
  useEffect(() => {
    map.flyTo([point.latitude, point.longitude], Math.max(map.getZoom(), 5), { duration: 0.35 });
  }, [map, point.latitude, point.longitude]);
  return null;
}
