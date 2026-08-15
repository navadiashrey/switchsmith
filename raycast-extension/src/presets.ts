// Mirrors Sources/Switchsmith/SwitchModel.swift's SwitchPresets.all.
// Kept as a plain constant (rather than fetched at runtime) since the
// extension has no persistent connection to the running app — control
// happens one-way, via switchsmith:// URLs.
export interface SwitchPreset {
  id: string;
  name: string;
  blurb: string;
}

export const presets: SwitchPreset[] = [
  { id: "cream", name: "Cream", blurb: "Warm, rounded, a little muted" },
  { id: "box-jade", name: "Box Jade", blurb: "Sharp, clacky, high-pitched snap" },
  { id: "linear-red", name: "Linear Red", blurb: "Soft, quiet, minimal transient" },
  { id: "buckling-spring", name: "Buckling Spring", blurb: "Loud, heavy, springy — an office from 1987" },
  { id: "topre", name: "Topre", blurb: "Deep, muted, electrostatic thock" },
];
