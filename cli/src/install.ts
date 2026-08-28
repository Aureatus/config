#!/usr/bin/env bun

import { mkdir, writeFile, copyFile, chmod, rename } from "node:fs/promises";
import { dirname, join } from "node:path";
import { getRepoRoot } from "./commands.ts";

const repoRoot = await getRepoRoot();
const cliRoot = join(repoRoot, "cli");
const distDir = join(cliRoot, "dist");
const executablePath = join(distDir, "forge");
const homeDir = process.env.HOME;

if (!homeDir) {
  console.error("HOME is not set, so forge cannot determine the install location.");
  process.exit(1);
}

console.log("Building standalone forge executable...");

const buildProcess = Bun.spawn({
  cmd: ["bun", "build", "--compile", "--outfile", executablePath, "src/index.ts"],
  cwd: cliRoot,
  stdin: "inherit",
  stdout: "inherit",
  stderr: "inherit",
  env: process.env,
});

const buildExit = await buildProcess.exited;
if (buildExit !== 0) {
  process.exit(buildExit);
}

const targetBinDir = join(homeDir, ".local", "bin");
const targetConfigDir = join(homeDir, ".config", "forge");
const installedBinaryPath = join(targetBinDir, "forge");
const stagedBinaryPath = join(targetBinDir, ".forge.next");
const repoConfigPath = join(targetConfigDir, "repo-root");

await mkdir(targetBinDir, { recursive: true });
await mkdir(targetConfigDir, { recursive: true });
await copyFile(executablePath, stagedBinaryPath);
await chmod(stagedBinaryPath, 0o755);
await rename(stagedBinaryPath, installedBinaryPath);
await writeFile(repoConfigPath, `${repoRoot}\n`, "utf8");

console.log(`Installed forge to ${installedBinaryPath}`);
console.log(`Stored repo root in ${repoConfigPath}`);
console.log("If ~/.local/bin is not on your PATH yet, add it to your shell config.");
