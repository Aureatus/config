import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export type CommandId =
  | "bootstrap"
  | "dev-env"
  | "devbox"
  | "vm-desktop"
  | "vm-desktop-reset"
  | "vm-smoke"
  | "vm-smoke-reset"
  | "desktop-config"
  | "system"
  | "capture"
  | "backup-kde"
  | "sync-ai"
  | "server-config";

export interface CommandDefinition {
  id: CommandId;
  title: string;
  description: string;
  category: string;
  command: string[];
  notes?: string[];
  requiresArgs?: boolean;
}

function pathExists(path: string): boolean {
  return existsSync(path);
}

async function readConfiguredRepoRoot(): Promise<string | null> {
  const homeDir = process.env.HOME;
  if (!homeDir) {
    return null;
  }

  const configPath = join(homeDir, ".config", "forge", "repo-root");
  if (!pathExists(configPath)) {
    return null;
  }

  const configuredRoot = (await Bun.file(configPath).text()).trim();
  if (!configuredRoot) {
    return null;
  }

  if (pathExists(join(configuredRoot, "setup.sh"))) {
    return configuredRoot;
  }

  return null;
}

async function findRepoRootFrom(startPath: string): Promise<string | null> {
  let current = startPath;

  while (true) {
    const setupPath = join(current, "setup.sh");
    const systemPath = join(current, "system");
    if (pathExists(setupPath) && pathExists(systemPath)) {
      return current;
    }

    const parent = dirname(current);
    if (parent === current) {
      return null;
    }

    current = parent;
  }
}

let cachedRepoRootPromise: Promise<string> | null = null;

export function getRepoRoot(): Promise<string> {
  if (!cachedRepoRootPromise) {
    cachedRepoRootPromise = (async () => {
      const envRoot = process.env.CONFIG_REPO_ROOT;
      if (envRoot && pathExists(join(envRoot, "setup.sh"))) {
        return envRoot;
      }

      const configuredRoot = await readConfiguredRepoRoot();
      if (configuredRoot) {
        return configuredRoot;
      }

      const cwdRoot = await findRepoRootFrom(process.cwd());
      if (cwdRoot) {
        return cwdRoot;
      }

      const execRoot = await findRepoRootFrom(dirname(process.execPath));
      if (execRoot) {
        return execRoot;
      }

      const sourceRoot = await findRepoRootFrom(dirname(fileURLToPath(import.meta.url)));
      if (sourceRoot) {
        return sourceRoot;
      }

      throw new Error(
        "Could not locate the config repo root. Run forge from inside the repo or set CONFIG_REPO_ROOT.",
      );
    })();
  }

  return cachedRepoRootPromise;
}

export async function getSetupPath(): Promise<string> {
  return join(await getRepoRoot(), "setup.sh");
}

export async function getCommandDefinitions(): Promise<CommandDefinition[]> {
  const setupPath = await getSetupPath();

  return [
    {
      id: "bootstrap",
      title: "Bootstrap Local Machine",
      description: "Run the preferred local-machine bootstrap path through Ansible.",
      category: "Machine",
      command: [setupPath, "bootstrap"],
    },
    {
      id: "desktop-config",
      title: "Apply Desktop Config",
      description: "Run the desktop Ansible playbook on localhost.",
      category: "Machine",
      command: [setupPath, "desktop-config"],
    },
    {
      id: "system",
      title: "Install System Packages",
      description: "Install curated apt packages and tracked Flatpak apps.",
      category: "Machine",
      command: [setupPath, "system"],
    },
    {
      id: "dev-env",
      title: "Install Mise Toolchain",
      description: "Install mise and the pinned shared runtimes.",
      category: "Tooling",
      command: [setupPath, "dev-env"],
    },
    {
      id: "devbox",
      title: "Install Optional Devbox",
      description: "Install the optional Devbox layer if a repo needs it.",
      category: "Tooling",
      command: [setupPath, "devbox"],
    },
    {
      id: "sync-ai",
      title: "Sync AI Config",
      description: "Sync shared AI guidance into OpenCode when Bun is available.",
      category: "Tooling",
      command: [setupPath, "sync-ai"],
    },
    {
      id: "vm-smoke",
      title: "Open Smoke VM",
      description: "Create or start the fast smoke VM and open the viewer.",
      category: "VM",
      command: [setupPath, "vm-smoke"],
    },
    {
      id: "vm-smoke-reset",
      title: "Reset Smoke VM",
      description: "Rebuild the smoke VM from the current repo state.",
      category: "VM",
      command: [setupPath, "vm-smoke-reset"],
    },
    {
      id: "vm-desktop",
      title: "Open Desktop VM",
      description: "Create or start the full desktop VM and open the viewer.",
      category: "VM",
      command: [setupPath, "vm-desktop"],
    },
    {
      id: "vm-desktop-reset",
      title: "Reset Desktop VM",
      description: "Rebuild the full desktop VM from the current repo state.",
      category: "VM",
      command: [setupPath, "vm-desktop-reset"],
    },
    {
      id: "capture",
      title: "Capture Machine State",
      description: "Export apt, Flatpak, and host metadata into system/state.",
      category: "Maintenance",
      command: [setupPath, "capture"],
    },
    {
      id: "backup-kde",
      title: "Backup KDE Config",
      description: "Archive KDE configuration outside the repo.",
      category: "Maintenance",
      command: [setupPath, "backup-kde"],
    },
    {
      id: "server-config",
      title: "Apply Server Config",
      description: "Run the server Ansible playbook against an inventory file.",
      category: "Remote",
      command: [setupPath, "server-config"],
      requiresArgs: true,
      notes: [
        "Pass an inventory file after the command id, for example: ansible/inventory/hosts.local.ini",
      ],
    },
  ];
}

export async function getCommandDefinition(id: string): Promise<CommandDefinition | undefined> {
  const definitions = await getCommandDefinitions();
  return definitions.find((definition) => definition.id === id);
}

export async function getRunnableCommands(): Promise<CommandDefinition[]> {
  const definitions = await getCommandDefinitions();
  return definitions.filter((definition) => !definition.requiresArgs);
}
