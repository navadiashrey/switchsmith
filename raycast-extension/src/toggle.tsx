import { closeMainWindow, open, showHUD } from "@raycast/api";

export default async function Command() {
  await open("switchsmith://toggle");
  await closeMainWindow();
  await showHUD("Switchsmith toggled");
}
