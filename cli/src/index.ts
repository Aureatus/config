#!/usr/bin/env bun

import { getCommandDefinition, getCommandDefinitions } from "./commands.ts";
import { describeCommand, runCommandById } from "./run.ts";
import { runTui } from "./tui.ts";

function printHelp(): void {
  console.log(`forge

Usage:
  bun run src/index.ts tui
  bun run src/index.ts list
  bun run src/index.ts describe <command-id>
  bun run src/index.ts run <command-id> [extra args...]
  bun run src/index.ts [--dry-run] <command-id> [extra args...]
  forge [--dry-run] <command-id> [extra args...]

Examples:
  bun run src/index.ts tui
  bun run src/index.ts list
  bun run src/index.ts run vm-smoke-reset
  bun run src/index.ts --dry-run vm-desktop-reset
  bun run src/index.ts run server-config ansible/inventory/hosts.local.ini
  forge tui
`);
}

async function main(): Promise<void> {
  const rawArgs = Bun.argv.slice(2);
  const dryRun = rawArgs.includes("--dry-run");
  const filteredArgs = rawArgs.filter((arg) => arg !== "--dry-run");
  const [subcommand = "tui", ...rest] = filteredArgs;

  switch (subcommand) {
    case "help":
    case "--help":
    case "-h":
      printHelp();
      return;
    case "tui":
      await runTui();
      return;
    case "list":
      for (const definition of await getCommandDefinitions()) {
        console.log(`${definition.id.padEnd(18)} ${definition.title}`);
      }
      return;
    case "describe": {
      const id = rest[0];
      if (!id) {
        console.error("Missing command id for describe.");
        process.exit(1);
      }

      const definition = await getCommandDefinition(id);
      if (!definition) {
        console.error(`Unknown command id: ${id}`);
        process.exit(1);
      }

      console.log(describeCommand(definition));
      return;
    }
    case "run": {
      const [id, ...extraArgs] = rest;
      if (!id) {
        console.error("Missing command id for run.");
        process.exit(1);
      }

      process.exit(await runCommandById(id, { dryRun, extraArgs }));
    }
    default:
      if (await getCommandDefinition(subcommand)) {
        process.exit(await runCommandById(subcommand, { dryRun, extraArgs: rest }));
      }

      console.error(`Unknown subcommand: ${subcommand}`);
      printHelp();
      process.exit(1);
  }
}

await main();
