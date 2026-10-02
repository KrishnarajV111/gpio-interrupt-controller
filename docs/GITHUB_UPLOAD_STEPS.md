# GitHub Upload - Exact Steps

Run these commands from the existing local Vivado project directory.

## First-time repository setup

```bash
git init
git branch -M main
git add .
git status
git commit -m "Initial GPIO interrupt controller implementation"
```

Create an empty repository on GitHub, then connect it:

```bash
git remote add origin https://github.com/<YOUR_USERNAME>/<YOUR_REPO>.git
git push -u origin main
```

## Adding the prepared documentation

Copy the prepared `README.md`, `docs/`, and `evidence/` directories into the project root before the `git add` step.

If the project is already a Git repository:

```bash
git add README.md docs/ evidence/
git status
git commit -m "Add design, verification, learning notes, and simulation evidence"
git push
```

## Recommended commit history

```text
1. Initial GPIO interrupt controller implementation
2. Add class-based SystemVerilog verification environment
3. Fix simulation top and monitor scheduling
4. Verify GPIO and interrupt functionality
5. Add project documentation and simulation evidence
```

Do not commit Vivado generated simulation/cache/run artifacts. The supplied `.gitignore` excludes the usual generated directories and logs.

## Quick verification after push

Open the repository on GitHub and check that at minimum these files are visible:

```text
README.md
docs/DESIGN_AND_VERIFICATION.md
docs/LEARNING_AND_DEBUG_NOTES.md
docs/GITHUB_UPLOAD_STEPS.md
evidence/final_waveform.png
evidence/simulation_pass.txt
```

Keep the actual RTL and SystemVerilog testbench files from the working Vivado project in the repository as well.
