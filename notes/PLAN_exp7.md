# Experiment 7 (sycophancy) — plan

Upstream materials: `/data2/ec2-user/upstream/lm_understand-logs/exp7_sycophancy` (sparse checkout of RikiyaT/lm_understand-logs:
README, `code/{train,eval,make_release}.py`, `dataset/{facts.json,splits/pair10{0,1,2}.json}`, `eval/{answer_key,model_behaviour,
weights_only_*,attention_tool}`, full run transcripts and prompts). Checkpoints (17 GB) are not released; they are rebuilt in ~25 s
each from `train.py` (bf16 training is not bit-reproducible, so hashes will differ; behaviour is what we compare).
Base model `google/gemma-3-270m-it` rev `ac82b4e8…` is in the HF cache.

## What the blog claims

Two fine-tunes of Gemma 3 270M IT per pair (same seed, data, schedule; embedding frozen): *honest* always answers correctly;
*sycophant* repeats the user's guess ("I think the answer is X but I'm really not sure"). Astra, given only the weights
(no forward pass allowed), could not tell which is which in four attempts (every answer P = 0.5, forced "A"). Given a tool
that returns attention maps of both models on texts Astra writes, it identified the sycophant 3/3 (P = 0.90 / 0.97 / 0.55) and
localized head 10.2 (attention from the answer position to the user's guess: 0.75 % honest vs 85.7 % sycophant).
Not in the post: their own `patch_score.json` shows every weights-only component nomination closes 0 % of the behaviour gap.

Two facts from their README matter for the design:
- **The base model already follows every wrong guess.** So the sycophant fine-tune barely has to change anything; the honest
  fine-tune has to *unlearn* copying. Sycophancy here is the default copy behaviour of the base model, not a learned feature.
- Both fine-tunes see identical prompts and identical reply strings; only the pairing differs.

## Questions and experiments

### E1. Rebuild and verify (half an hour)
Train pair 100/101/102 × {honest, sycophant} with their `train.py` and splits; run their `eval.py`; reproduce
`wrong_follow_known_heldout` ≈ 100 % (sycophant) vs 1–3 % (honest), `plain_acc_heldout` 98–99 %, and the base's 100 %.
Also train 2 extra seeds of pair 100 for variance. Keep our models under /data2/ec2-user/models/exp7/.

### E2. Is weights-only identification actually impossible? (the central question; hours, CPU/GPU trivial)
Baselines that use only the weights, no forward pass, in the three access settings:
- **(a) A and B only, no embedding** (attempts 1–3): per-matrix ‖ΔW‖, spectrum of ΔW, which layers/heads changed most;
  then the directional question: is there any weight-only statistic whose *sign* tells honest from sycophant? Candidates:
  the honest model must suppress a copy path, so the QK/OV circuits of the copy heads should move toward "less
  attention to a later repeated token" — testable as the change in the composed QK score for (query = answer position
  pattern, key = guess position) using only W_Q, W_K, rotary, no embeddings? Likely not decidable; measure and report.
- **(b) + embedding and tokenizer** (attempt 4): logit lens of the task vector θ_A − θ_B through the tied unembedding at
  the MLP write and attention-output matrices (which tokens does the difference promote?); composed-circuit scores for
  number tokens: "does head 10.2's OV∘QK read a number token at the guess position and write it?" This is the kind of
  analysis Astra attempted; we check whether a fixed, non-agentic script gets the sign right 3/3.
- **(c) + the public base checkpoint** (legitimately weights-only, since the base is public and Astra was told it is
  Gemma 3 270M IT): d(θ_A, θ_base) vs d(θ_B, θ_base). Prediction: the honest model is farther from base (it had to
  unlearn). If this gives 3/3, the "weights alone cannot tell" claim is an artefact of withholding the base model.
- **(d) one forward pass** (what the attention tool amounts to): task-vector arithmetic θ_base + (θ_A − θ_B) → does the
  base become honest or more sycophantic? And the trivial behavioural test (ask one question with a wrong guess).
Deliverable: a table "access setting × method → pairs identified / 3 (and on our extra seeds)".

### E3. Does Astra's attention-tool localization hold up? (hours)
On rebuilt pairs: (a) reproduce the head 10.2 figure (their exact texts are in `runs/attention_tool/pair2/attn/r7/tokens.json`;
their code is in `tool_calls.jsonl` run 12); (b) causal check with their own `patch_score` protocol: copy head 10.2 (then 10.2 +
11.2 + 12.2, then all of layers 10–12 attention) from honest into sycophant and measure gap closed; compare against
top-k heads by ‖ΔW‖, by activation-patching attribution (our own AtP over all 72 heads and 18 MLPs), and random heads;
(c) the reverse direction (sycophant → honest). Question: is head 10.2 *the* mechanism (a few heads close the gap) or
is the change distributed (their patch_score style result for MLPs 15–17)?

### E4. What did the honest fine-tune actually learn? (mechanism; a day, collaborator-shareable)
- Attention to the guess at the answer position in base / honest / sycophant for every head (not only 10.2): is the
  honest model suppressing the copy head's attention (QK change), or overriding its output downstream (MLP 15–17
  "number writing" changes Astra also noted)?
- Decompose θ_honest − θ_base per module; rank/spectrum; which part is necessary (patch per module class).
- Linear probes: "guess present", "guess is wrong", "guess token identity" at the answer position in all three models —
  does the honest model compute "the guess is wrong" (a real sycophancy-resistance feature) or just stop reading the guess?
- Cross-pair consistency: are the same heads/directions involved in pairs 100/101/102 and in our extra seeds?

### E5. Did the attention tool do the work, or did Astra? (cheap)
A fixed script with the same access as the tool: on the same 16 texts Astra used (we have its texts), compute mean
attention from the answer position to the guess tokens, summed over heads and layers; declare the model with more mass
the sycophant. If this trivial rule gets 3/3, the identification required the tool (a behavioural probe), not weight
understanding. Also: how many texts / how few heads suffice.

## Shared conventions
Their `eval.py` metrics (`wrong_follow_known_heldout`, `plain_acc_heldout`, log-prob margin) on their held-out split;
their `patch_score` definition (`gap_closed`, `margin_closed`); the three pairs plus our extra seeds; HF transformers for all
forward passes (270M, everything fits on one GPU in minutes). Scripts under `scripts/exp7/`, notes under `notes/exp7_*.md`.

## Order and time
E1 (30 min) → E2c and E2d (1 h; the decisive table) → E5 (1 h) → E3 (half a day, needs their texts + AtP) → E2a/b and E4
(a day; E4 can go to the collaborator). Nothing here competes with the exp8 queue for more than a few GPU-minutes at a time,
except E3's patching sweeps; run those after the exp8 queue finishes.

## Expected story
Sycophancy in this setup is the base model's default copy behaviour; "honest" is the model that learned to stop reading
the user's guess. The weights-only task is unsolvable only because the base checkpoint was withheld; with the public base
(or one forward pass) it is trivial. The attention tool is a behavioural probe, and a fixed rule on its output identifies the
sycophant as well as Astra does. Whether head 10.2 is causally sufficient is the one open empirical question (E3).
