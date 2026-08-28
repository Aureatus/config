import {
  BoxRenderable,
  createCliRenderer,
  SelectRenderable,
  SelectRenderableEvents,
  TextAttributes,
  TextRenderable,
  type KeyEvent,
  type SelectOption,
} from "@opentui/core";
import { getCommandDefinitions, getRunnableCommands, type CommandDefinition } from "./commands.ts";
import { describeCommand, runCommandDefinition } from "./run.ts";

interface TuiState {
  selectedIndex: number;
}

const palette = {
  appBg: "#0b1117",
  panelBg: "#101923",
  panelBgAlt: "#0d1620",
  panelBgSoft: "#132132",
  border: "#39516b",
  borderStrong: "#5f86ab",
  text: "#eef4fb",
  textSoft: "#9eb3c8",
  textMuted: "#6f879f",
  accent: "#7dd3fc",
  accentSoft: "#17314a",
  accentStrong: "#1f4161",
  success: "#6ee7b7",
  warning: "#fbbf24",
};

function buildCommandNotes(definition: CommandDefinition): string {
  const notes = definition.notes?.length
    ? definition.notes
    : ["Runs from the repo root so relative paths keep working."];

  return notes.map((note) => `- ${note}`).join("\n");
}

function buildDetailSummary(definition: CommandDefinition): string {
  return `${definition.description}\n\nCategory: ${definition.category}\nCommand id: ${definition.id}`;
}

export async function runTui(): Promise<number> {
  const renderer = await createCliRenderer({
    exitOnCtrlC: false,
    consoleMode: "disabled",
  });

  const runnableCommands = await getRunnableCommands();
  const allCommands = await getCommandDefinitions();
  const hiddenCommands = allCommands.filter((definition) => definition.requiresArgs).map((definition) => definition.id);
  const state: TuiState = { selectedIndex: 0 };

  const root = new BoxRenderable(renderer, {
    id: "forge-root",
    width: "100%",
    height: "100%",
    flexDirection: "column",
    padding: 1,
    gap: 1,
    backgroundColor: palette.appBg,
  });

  const header = new BoxRenderable(renderer, {
    id: "forge-header",
    borderStyle: "rounded",
    borderColor: palette.borderStrong,
    backgroundColor: palette.panelBg,
    padding: 1,
    height: 6,
    flexDirection: "column",
    gap: 0,
  });

  const eyebrow = new TextRenderable(renderer, {
    id: "forge-eyebrow",
    content: "ANSIBLE-FIRST · MISE-POWERED · VM READY",
    fg: palette.accent,
    selectable: false,
  });

  const title = new TextRenderable(renderer, {
    id: "forge-title",
    content: "forge - command center",
    fg: palette.text,
    attributes: TextAttributes.BOLD,
    selectable: false,
  });

  const subtitle = new TextRenderable(renderer, {
    id: "forge-subtitle",
    content: "Launch local bootstrap, VM workflows, backups, and shared config tasks.",
    fg: palette.textSoft,
    selectable: false,
  });

  const chipRow = new BoxRenderable(renderer, {
    id: "forge-chip-row",
    flexDirection: "row",
    gap: 1,
    height: 1,
  });

  const chips = [
    { id: "chip-machine", text: `${allCommands.filter((definition) => definition.category === "Machine").length} machine`, color: palette.warning },
    { id: "chip-vm", text: `${allCommands.filter((definition) => definition.category === "VM").length} vm`, color: palette.success },
    { id: "chip-tooling", text: `${allCommands.filter((definition) => definition.category === "Tooling").length} tooling`, color: palette.accent },
  ].map((chip) => {
    const node = new TextRenderable(renderer, {
      id: chip.id,
      content: chip.text.toUpperCase(),
      fg: chip.color,
      selectable: false,
    });
    chipRow.add(node);
    return node;
  });

  header.add(eyebrow);
  header.add(title);
  header.add(subtitle);
  header.add(chipRow);

  const body = new BoxRenderable(renderer, {
    id: "forge-body",
    flexDirection: "row",
    flexGrow: 1,
    gap: 1,
  });

  const listPanel = new BoxRenderable(renderer, {
    id: "forge-list-panel",
    width: 44,
    height: "100%",
    borderStyle: "rounded",
    borderColor: palette.border,
    backgroundColor: palette.panelBgAlt,
    title: "Actions",
    padding: 1,
    flexDirection: "column",
    gap: 1,
  });

  const listIntro = new TextRenderable(renderer, {
    id: "forge-list-intro",
    content: "Move with arrows or j/k. Press Enter to run.",
    fg: palette.textMuted,
    selectable: false,
  });

  const options: SelectOption[] = runnableCommands.map((definition) => ({
    name: definition.title,
    description: `${definition.category} · ${definition.id}`,
    value: definition.id,
  }));

  const commandList = new SelectRenderable(renderer, {
    id: "forge-command-list",
    width: "100%",
    height: 18,
    flexGrow: 1,
    options,
    selectedIndex: 0,
    showDescription: true,
    showScrollIndicator: true,
    wrapSelection: true,
    backgroundColor: palette.panelBgAlt,
    focusedBackgroundColor: palette.panelBgAlt,
    selectedBackgroundColor: palette.accentSoft,
    selectedTextColor: palette.text,
    selectedDescriptionColor: palette.accent,
    textColor: palette.text,
    descriptionColor: palette.textMuted,
  });

  listPanel.add(listIntro);
  listPanel.add(commandList);

  const detailPanel = new BoxRenderable(renderer, {
    id: "forge-detail-panel",
    flexGrow: 1,
    height: "100%",
    borderStyle: "rounded",
    borderColor: palette.border,
    backgroundColor: palette.panelBgAlt,
    title: "Selection",
    padding: 1,
    flexDirection: "column",
    gap: 1,
  });

  const selectionHeader = new BoxRenderable(renderer, {
    id: "forge-selection-header",
    borderStyle: "single",
    borderColor: palette.border,
    backgroundColor: palette.panelBgSoft,
    padding: 1,
    height: 8,
    flexDirection: "column",
    gap: 0,
  });

  const categoryText = new TextRenderable(renderer, {
    id: "forge-category",
    content: runnableCommands[0]?.category.toUpperCase() ?? "",
    fg: palette.accent,
    selectable: false,
  });

  const selectionTitle = new TextRenderable(renderer, {
    id: "forge-selection-title",
    content: runnableCommands[0]?.title ?? "",
    fg: palette.text,
    attributes: TextAttributes.BOLD,
    selectable: false,
  });

  const selectionSummary = new TextRenderable(renderer, {
    id: "forge-selection-summary",
    content: buildDetailSummary(runnableCommands[0]),
    fg: palette.textSoft,
    selectable: false,
  });

  selectionHeader.add(categoryText);
  selectionHeader.add(selectionTitle);
  selectionHeader.add(selectionSummary);

  const commandPanel = new BoxRenderable(renderer, {
    id: "forge-command-panel",
    borderStyle: "single",
    borderColor: palette.border,
    backgroundColor: palette.panelBg,
    title: "Shell Command",
    padding: 1,
    height: 5,
  });

  const commandText = new TextRenderable(renderer, {
    id: "forge-command-text",
    content: describeCommand(runnableCommands[0]).split("\n").find((line) => line.startsWith("Command:")) ?? "",
    fg: palette.success,
  });

  commandPanel.add(commandText);

  const notePanel = new BoxRenderable(renderer, {
    id: "forge-note-panel",
    borderStyle: "single",
    borderColor: palette.border,
    backgroundColor: palette.panelBg,
    title: "Context",
    padding: 1,
    flexGrow: 1,
  });

  const noteText = new TextRenderable(renderer, {
    id: "forge-note-text",
    content: buildCommandNotes(runnableCommands[0]),
    fg: palette.textSoft,
  });

  notePanel.add(noteText);

  detailPanel.add(selectionHeader);
  detailPanel.add(commandPanel);
  detailPanel.add(notePanel);

  const footer = new BoxRenderable(renderer, {
    id: "forge-footer",
    borderStyle: "rounded",
    borderColor: palette.borderStrong,
    backgroundColor: palette.panelBg,
    padding: 1,
    height: 3,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
  });

  const footerLeft = new TextRenderable(renderer, {
    id: "forge-footer-left",
    content: "Enter run   j/k or arrows move   q quit",
    fg: palette.textSoft,
    selectable: false,
  });

  const footerRight = new TextRenderable(renderer, {
    id: "forge-footer-right",
    content: hiddenCommands.length ? `Needs args: ${hiddenCommands.join(", ")}` : "All commands available in TUI",
    fg: palette.textMuted,
    selectable: false,
  });

  footer.add(footerLeft);
  footer.add(footerRight);

  body.add(listPanel);
  body.add(detailPanel);

  root.add(header);
  root.add(body);
  root.add(footer);
  renderer.root.add(root);

  const updateLayout = () => {
    const sidebarWidth = Math.max(40, Math.min(48, Math.floor(renderer.width * 0.32)));
    const listHeight = Math.max(12, renderer.height - 18);
    listPanel.width = sidebarWidth;
    selectionHeader.height = renderer.height < 28 ? 7 : 8;
    commandList.height = listHeight;
  };

  const refreshDetails = () => {
    const current = runnableCommands[state.selectedIndex] ?? runnableCommands[0];
    categoryText.content = current.category.toUpperCase();
    selectionTitle.content = current.title;
    selectionSummary.content = buildDetailSummary(current);
    commandText.content = current.command.join(" ");
    noteText.content = buildCommandNotes(current);
  };

  const quit = () => {
    renderer.destroy();
    process.exit(0);
  };

  const launch = async (definition: CommandDefinition) => {
    renderer.destroy();
    const exitCode = await runCommandDefinition(definition);
    process.exit(exitCode);
  };

  commandList.on(SelectRenderableEvents.SELECTION_CHANGED, (index: number) => {
    state.selectedIndex = index;
    refreshDetails();
  });

  commandList.on(SelectRenderableEvents.ITEM_SELECTED, async (index: number) => {
    state.selectedIndex = index;
    await launch(runnableCommands[index]);
  });

  renderer.keyInput.on("keypress", async (key: KeyEvent) => {
    if (key.ctrl && key.name === "c") {
      quit();
    }

    if (key.name === "escape" || key.name === "q") {
      quit();
    }
  });

  renderer.on("resize", () => {
    updateLayout();
  });

  commandList.focus();
  updateLayout();
  refreshDetails();

  return await new Promise<number>(() => {
    // Keep the renderer alive until a selection or quit occurs.
  });
}
