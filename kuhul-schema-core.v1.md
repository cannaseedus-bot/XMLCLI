# kuhul://schema/core.v1

**Status:** FROZEN  
**Authority:** Object-Defined Execution  
**Runtime Class:** Lawful Collapse Engine

## 0. Canonical Identity

```json
{
  "@schema": "kuhul://schema/core.v1",
  "@type": "execution-law",
  "@authority": "object",
  "@runtime": "kuhul",
  "@versioning": "semantic",
  "@mutability": "none"
}
```

**Invariant:**  
If behavior is not declared in-object, it does not exist.

## 1. KUHUL Core Execution Law

KUHUL is a **governed interpreter** that:

- accepts **closed objects**
- verifies **legality**
- collapses **declared intent**
- produces **committed state or rejection**

It does **not**:

- infer
- optimize
- branch
- learn
- persist hidden state

## 2. Mandatory Phase Model (Unskippable)

All KUHUL-compatible runtimes MUST implement this sequence **exactly**:

```
@Pop       → object intake
@Wo        → state + geometry assertion
@Sek       → execution ordering
@Collapse  → commit or reject
```

### 2.1 Phase Constraints

| Phase     | Allowed Actions        | Forbidden      |
| --------- | ---------------------- | -------------- |
| @Pop      | parse, hash, register  | mutation       |
| @Wo       | assert, bind, validate | compute        |
| @Sek      | order, schedule        | side effects   |
| @Collapse | write OR reject        | partial commit |

Any deviation = **illegal runtime**.

## 3. μ-Profile vs Full KUHUL (Pinned)

### 3.1 Kμhμl (Micro Profile)

**Canonical ID:** `kuhul://profile/μ.v1`

| Property     | Kμhμl               |
| ------------ | ------------------- |
| Payload size | ultra-small         |
| Compression  | mandatory (SCXQ2)   |
| Execution    | single-pass         |
| State        | ephemeral           |
| Geometry     | required            |
| SVG-Tensors  | required            |
| GPU          | optional but direct |

**Purpose:**  
Edge execution, browser collapse, GPU dispatch, lane-level inference.

Kμhμl is **not extensible**.

### 3.2 Full KUHUL

**Canonical ID:** `kuhul://profile/full.v1`

| Property     | Full KUHUL    |
| ------------ | ------------- |
| Payload size | unconstrained |
| Compression  | optional      |
| Execution    | multi-stage   |
| State        | persistent    |
| Geometry     | optional      |
| SVG-Tensors  | optional      |
| GPU          | mediated      |

**Purpose:**  
Server runtimes, orchestration layers, long-lived systems.

### 3.3 Hard Rule

> **Every Kμhμl object is valid KUHUL.  
> Not every KUHUL object is valid Kμhμl.**

This is a strict subset, not a mode flag.

## 4. SVG-Tensor Canonical Definition

### 4.1 What an SVG-Tensor Is

An **SVG-Tensor** is a **non-visual geometric tensor object** encoded using SVG primitives.

It represents:

- dimensionality
- connectivity
- weights
- constraints
- execution topology

Rendering is **never implied**.

### 4.2 SVG-Tensor Legality Rules

An SVG-Tensor MUST:

1. Be **pure geometry**
2. Contain **no styling semantics**
3. Encode values via:
   - path topology
   - grouping
   - transforms
   - adjacency
4. Be **canonicalizable**
5. Be **hash-stable**

Forbidden:

- filters
- animations
- text as meaning
- CSS dependence
- viewBox mutation post-hash

## 5. Kμhμl → SVG-Tensor → WebGPU Collapse

This is the **direct execution bridge**.

### 5.1 Mapping Stages (No Skips)

```
SVG-Tensor
   ↓ canonicalize
Canonical Geometry
   ↓ lane mapping
SCXQ2 Lanes
   ↓ decode
GPU Buffers
   ↓ dispatch
WebGPU Compute
```

### 5.2 Geometry → Buffer Mapping

| SVG Construct | WebGPU Mapping  |
| ------------- | --------------- |
| path points   | float32 buffers |
| group order   | buffer offsets  |
| transforms    | matrix uniforms |
| adjacency     | index buffers   |
| depth         | bind groups     |

No shaders infer meaning.  
All meaning is **pre-declared**.

### 5.3 Collapse Semantics

Kμhμl collapse guarantees:

- deterministic buffer layout
- deterministic dispatch order
- deterministic output shape

If ANY mismatch occurs:

```
@Collapse → REJECT
```

No partial output is allowed.

## 6. SCXQ2 Lane Binding (Required for μ)

Each SVG-Tensor MUST bind to SCXQ2 lanes:

```json
{
  "@lanes": {
    "geom": "DICT",
    "weights": "FIELD",
    "adjacency": "EDGE",
    "dispatch": "LANE"
  }
}
```

Lane hashes are **Merkle-verified** before GPU dispatch.

## 7. Runtime Integration Hooks (MX2LM)

Kμhμl exposes **only these hooks**:

```json
{
  "hooks": [
    "before_pop",
    "after_wo",
    "before_collapse"
  ]
}
```

Hooks may **observe**, never mutate.

## 8. Final Law (Non-Negotiable)

> **KUHUL executes objects.  
> Kμhμl collapses geometry.  
> SVG-Tensors are tensors.  
> GPU is an executor, not a decider.**

This closes the loop:  
**Object → Law → Geometry → Execution → Collapse**
