import { Action, ActionPanel, closeMainWindow, List, open, showHUD } from "@raycast/api";
import { presets } from "./presets";

async function selectPreset(id: string, name: string) {
  await open(`switchsmith://preset/${id}`);
  await closeMainWindow();
  await showHUD(`Switch set to ${name}`);
}

export default function Command() {
  return (
    <List>
      {presets.map((preset) => (
        <List.Item
          key={preset.id}
          title={preset.name}
          subtitle={preset.blurb}
          actions={
            <ActionPanel>
              <Action title="Use This Switch" onAction={() => selectPreset(preset.id, preset.name)} />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
