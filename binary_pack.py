import argparse
import json
import struct
from pathlib import Path

import numpy as np

MAGIC = b"MXAT"
VERSION = 1
DTYPE_CODES = {
    "uint16": 1,
    "uint32": 2,
}
CODE_DTYPES = {v: k for k, v in DTYPE_CODES.items()}


def load_and_clean(path: Path, strip_html: bool) -> str:
    text = path.read_text(encoding="utf-8", errors="ignore")

    if path.suffix.lower() == ".json":
        try:
            obj = json.loads(text)
            text = json.dumps(obj, separators=(",", ":"), ensure_ascii=False)
        except json.JSONDecodeError:
            pass

    if strip_html:
        text = text.replace("<", " ").replace(">", " ")

    return text


def pi_tokenize(text: str, vocab_size: int) -> list[int]:
    return [ord(char) % vocab_size for char in text]


def write_header(handle, *, dtype_name: str, atom_size: int, vocab_size: int, token_count: int) -> None:
    dtype_code = DTYPE_CODES[dtype_name]
    header = struct.pack(
        "<4sHBBIIQ",
        MAGIC,
        VERSION,
        dtype_code,
        0,
        atom_size,
        vocab_size,
        token_count,
    )
    handle.write(header)


def pack_directory(
    input_dir: Path,
    out_file: Path,
    atom_size: int,
    vocab_size: int,
    dtype_name: str,
    extensions: tuple[str, ...],
    strip_html: bool,
) -> None:
    tokens: list[int] = []

    for path in sorted(input_dir.rglob("*")):
        if path.is_file() and path.suffix.lower() in extensions:
            text = load_and_clean(path, strip_html)
            tokens.extend(pi_tokenize(text, vocab_size))

    pad = (-len(tokens)) % atom_size
    if pad:
        tokens.extend([0] * pad)

    dtype = np.dtype(dtype_name)
    arr = np.array(tokens, dtype=dtype)

    with out_file.open("wb") as handle:
        write_header(
            handle,
            dtype_name=dtype_name,
            atom_size=atom_size,
            vocab_size=vocab_size,
            token_count=len(arr),
        )
        arr.tofile(handle)

    atom_count = len(arr) // atom_size
    print(f"[OK] Packed {len(arr)} tokens")
    print(f"[OK] Atoms: {atom_count}")
    print(f"[OK] Output: {out_file}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Pack text sources into MATRIX atom binary form.")
    parser.add_argument("input_dir", type=Path, help="Directory of source files.")
    parser.add_argument("out_file", type=Path, help="Output binary file.")
    parser.add_argument("--atom-size", type=int, default=256, help="Tokens per atom.")
    parser.add_argument("--vocab-size", type=int, default=65536, help="Vocabulary size.")
    parser.add_argument(
        "--dtype",
        choices=sorted(DTYPE_CODES.keys()),
        default="uint16",
        help="Token storage dtype.",
    )
    parser.add_argument(
        "--extensions",
        nargs="+",
        default=[".txt", ".md", ".html", ".json"],
        help="File extensions to ingest.",
    )
    parser.add_argument(
        "--no-html-strip",
        action="store_true",
        help="Disable minimal HTML tag stripping.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    extensions = tuple(ext.lower() for ext in args.extensions)
    pack_directory(
        args.input_dir,
        args.out_file,
        atom_size=args.atom_size,
        vocab_size=args.vocab_size,
        dtype_name=args.dtype,
        extensions=extensions,
        strip_html=not args.no_html_strip,
    )


if __name__ == "__main__":
    main()
