# EditLens: what did Astra's weight edit actually do?

Code and results for checking the language-model experiments in
[*Sparks of Weight-Space Programming*](https://rikiyat.github.io/blog/weight-space-programming/) (Takehi, Teoh, Zhang & Khattab, 2026),
where GPT-6 Astra edits model weights directly, without training. We rebuild the edits, reproduce the results, and test
Astra's explanations with ten interpretability tools and controls that change the model.

- **Article:** [EditLens: What Did Astra's Edit Actually Do?](https://xxlya.github.io/editlens/)
- **Short blog:** [What did Astra's weight edit actually program?](https://assassin808.github.io/astra-blog/)
- **All numbers in one place:** [`results/RESULTS.md`](results/RESULTS.md). Where an older note disagrees, RESULTS.md wins.

Authors: Xuanqi Zhang\*, HaoYang Shang\*, Xiaoxiao Li† (University of British Columbia, Vector Institute). \*Equal contribution, †corresponding author.

## The edit in one paragraph

In its 50-run attempt, Astra changed 64 output columns of `mlp.down_proj` in each of layers 15 and 19 of Qwen3.5-0.8B
(`astra_logs/exp8_math/runs/p50c/edit/`). The change is rank one per layer: `w' = w − α u (uᵀw)` with α = 6, which flips the
component along `u` and makes it five times larger. MATH-500 rises from 7.9% to 48.1% in the original post; our rebuild gives
7.6% → 51.9% under the same protocol.

## Where to find each result

The folders follow the sections of the article.

### 01 · What the edit changes in behaviour — `results/01_behaviour/`

| Question | Result files | Scripts |
|---|---|---|
| Is the gain about finishing or about solving? Thinking off, forced stop, repetition penalty | `screen/table*.md`, `screen/table.json` | `screen_eval.py`, `summarize_screen.py` |
| Completion vs accuracy in Astra's own logs | `finding1_completion_vs_accuracy.md` | `finding1_from_logs.py` |
| Failure types of the edited model | `failure_classes.md` | `failure_classes_from_logs.py` |
| Smoke tests of the rebuilt models | `q0_smoke_generation.md` | `smoke_generate.py`, `vllm_smoke.py` |

### 02 · How the edit breaks loops — `results/02_loops/`

One folder per tool, in the order the effect travels through the model.

| Folder | Tool and question | Main note | Scripts |
|---|---|---|---|
| `weights/` | Weight-difference SVD: what changed? (rank one, α = 6) | `q1_what_changed.md` | `q1_delta_w.py`, `q1_rank1_structure.py`, `test1_shared_u.py` |
| `neurons/` | Activation ranking and auto-interpretation: which neurons, what do they fire on? | `test3_neurons.md` | `q2_neuron_activations.py`, `test3_*.py` |
| `lenses/` | Logit, tuned, Jacobian and R-lenses: what does `u` mean? | `test2_lenses.md` | `test2_*.py` |
| `sae/` | Sparse autoencoders: which features? | `test4_sae.md` | `test4_*.py` |
| `steering/` | Activation steering along `−u`, with weights untouched | `q4_simpler_intervention.md` | `q4_tf_interventions.py`, `steer_eval.py` |
| `paths/` | Path patching and attribution patching: which route carries the effect? | `test5_paths.md` | `q3_who_reads_u.py`, `test5_*.py` |
| `states/` | Probes, class means, state geometry: does the edit restore a normal state? | `test8_probe.md`, `q5_state_geometry.md` | `q5_state_geometry.py`, `test8_*.py` |
| `overshoot/` | Can the side effects be removed without losing the fix? (pre-registered screen and confirmation) | `sidefx.md`, `sidefx_confirm.md` | `sidefx_*.py` |
| `cheap_score/` | Does a loss on old loop text rank edits correctly? | `q4b_tf_sweep.md` | `q4b_tf_sweep.py` |
| `doubt/` | Does the model know when it is right? Where do loops start? What do failures look like? | `expA_calibrated_doubt.md`, `loop_onset.md`, `expB_paraphrase_loops.md`, `api_failure_labels.md` | `expA_*.py`, `onset_*.py`, `expB_*.py`, `api/` |
| `generality/` | Effects on non-math text | `q6_side_effects_generality.md` | `q6_tf_nonmath.py` |

Figures sit in the `fig/` folder of each section.

### 03 · Attention and sycophancy — `results/03_sycophancy/`

Experiment 7: Astra identifies the sycophantic Gemma 3 270M fine-tune from attention patterns. The plan is in
`PLAN_exp7.md`. Weight swaps, activation patching and the full toolkit on the rebuilt pairs are reported in the article;
their code and data are maintained by Xuanqi Zhang and will be added here.

### 04 · What the next edit must show

The checks we suggest for any AI-written edit:
1. Establish the behaviour and compare with simple changes outside the weights.
2. Inspect the weight change.
3. Explain it with several tools, each with random controls.
4. Test by intervention.
5. Validate on new problems, reporting gains and side effects together.

Each analysis here was pre-registered in its note, and failed predictions are kept.

## Repository layout

```
astra_logs/   copy of Astra's public logs and edits (CC BY 4.0; scripts MIT), from RikiyaT/lm_understand-logs
data/         benchmark files (GSM8K test, MATH-500, IFEval and MMLU-Pro subsets)
shared/       the edit direction u, Astra's columns and our neuron rankings (.npy)
scripts/      all analysis code; scripts/astra_eval/ is the shared generation and grading harness
results/      notes, result files and figures, by section (above); writing/ holds drafts, plans/ the work plans
alliance/     setup and job scripts for Compute Canada / Vector clusters
```

## Reproduce

- Rebuild an edited model:
  `python astra_logs/exp8_math/code/apply_edit.py <base model.safetensors> astra_logs/exp8_math/runs/p50c/edit <out>`.
  Base model: `Qwen/Qwen3.5-0.8B`, revision `2fc06364715b967f1860aea9cf38778875588b17`.
- Generation uses vLLM with `VLLM_USE_FLASHINFER_SAMPLER=0`. Large per-sample outputs are not in git.
- On another cluster: `alliance/setup.sh`, then `alliance/job.sh <branch> scripts/portable_*.sh`.

## Credits

Astra's logs, edits and evaluation code are by Takehi, Teoh, Zhang and Khattab (MIT CSAIL); see `astra_logs/LICENSE`.
