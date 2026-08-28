import { getCommandDefinition, getRepoRoot, type CommandDefinition } from "./commands.ts";

export interface RunCommandOptions {
  extraArgs?: string[];
  dryRun?: boolean;
}

function shellEscape(part: string): string {
  if (part.length === 0) {
    return "''";
  }

  if (/^[A-Za-z0-9_./:-]+$/.test(part)) {
    return part;
  }

  return `'${part.replace(/'/g, `'"'"'`)}'`;
}

function formatCommand(command: string[], extraArgs: string[] = []): string {
  return [...command, ...extraArgs].map(shellEscape).join(" ");
}

export async function runCommandDefinition(definition: CommandDefinition, options: RunCommandOptions = {}): Promise<number> {
  const extraArgs = options.extraArgs ?? [];

  if (options.dryRun) {
    console.log(formatCommand(definition.command, extraArgs));
    return 0;
  }

  const repoRoot = await getRepoRoot();
  const subprocess = Bun.spawn({
    cmd: [...definition.command, ...extraArgs],
    cwd: repoRoot,
    stdin: "inherit",
    stdout: "inherit",
    stderr: "inherit",
    env: process.env,
  });

  return await subprocess.exited;
}

export async function runCommandById(id: string, options: RunCommandOptions = {}): Promise<number> {
  const definition = await getCommandDefinition(id);
  if (!definition) {
    console.error(`Unknown command id: ${id}`);
    return 1;
  }

  if (definition.requiresArgs && (options.extraArgs?.length ?? 0) === 0) {
    console.error(`Command '${id}' requires extra arguments.`);
    return 1;
  }

  return await runCommandDefinition(definition, options);
}

export function describeCommand(definition: CommandDefinition): string {
  const lines = [
    `${definition.title}`,
    `${definition.description}`,
    `Category: ${definition.category}`,
    `Command: ${formatCommand(definition.command)}`,
  ];

  if (definition.requiresArgs) {
    lines.push("Requires extra args: yes");
  }

  if (definition.notes?.length) {
    lines.push("Notes:");
    for (const note of definition.notes) {
      lines.push(`- ${note}`);
    }
  }

  return lines.join("\n");
}
