export type SharedSkill = {
  source: string;
  enabled: boolean;
  note: string;
};

// `source` is passed directly to `bunx skills add`, so any source string
// supported by the skills CLI can be used here.
export const skills: readonly SharedSkill[] = [
  {
    source: "anthropics/skills@frontend-design",
    enabled: true,
    note: "Distinctive frontend and interface design workflow.",
  },
  {
    source: "anthropics/skills@webapp-testing",
    enabled: true,
    note: "Browser-oriented testing guidance for real web app behavior.",
  },
  {
    source: "obra/superpowers@verification-before-completion",
    enabled: true,
    note: "Reinforces verifying work before claiming it is done.",
  },
  {
    source: "obra/superpowers@requesting-code-review",
    enabled: true,
    note: "Reusable workflow for structured code review requests.",
  },
] as const;
