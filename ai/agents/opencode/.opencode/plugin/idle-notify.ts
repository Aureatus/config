import { basename } from "node:path";
import type { Plugin } from "@opencode-ai/plugin";

const NOTIFICATION_EXPIRE_MS = 10_000;

const debug = (..._args: unknown[]) => {
  /* intentional no-op debug helper */
};

type PluginInput = Parameters<Plugin>[0];

type HandleIdleArgs = {
  $: PluginInput["$"];
  client: PluginInput["client"];
  sessionID: string;
  sessionName: string;
};

const notifyIdle = async ($: PluginInput["$"], sessionName: string) => {
  const title = `${sessionName} - Awaiting Input`;
  const summary = `Session ${sessionName} is idle.`;

  try {
    await $`notify-send -u normal -t ${NOTIFICATION_EXPIRE_MS} ${title} ${summary}`
      .quiet()
      .nothrow();

    // Play a sound using paplay (PulseAudio)
    await $`paplay /usr/share/sounds/Pop/stereo/notification/complete.oga`
      .quiet()
      .nothrow();
  } catch {
    // ignore notification failures
  }
};

const handleIdle = async ({
  $,
  sessionName,
}: HandleIdleArgs) => {
  debug("session idle", sessionName);
  await notifyIdle($, sessionName);
};

export const IdleNotify: Plugin = ({ $, client, directory }) => {
  const sessionName = basename(directory).trim() || "Session";
  let running = false;

  return Promise.resolve({
    event: async ({ event }) => {
      if (event.type !== "session.idle" || running) {
        return;
      }

      const sessionID = (event as { properties?: { sessionID?: string } })
        .properties?.sessionID;
      if (!sessionID) {
        return;
      }

      running = true;

      try {
        await handleIdle({ $, client, sessionID, sessionName });
      } catch (error) {
        debug("failure", error);
        await $`notify-send -u normal -t ${NOTIFICATION_EXPIRE_MS} ${sessionName} "Idle notification plugin failed"`
          .quiet()
          .nothrow();

        // Play a sound using paplay (PulseAudio)
        await $`paplay /usr/share/sounds/Pop/stereo/notification/complete.oga`
          .quiet()
          .nothrow();
      } finally {
        running = false;
      }
    },
  });
};