"""Scoring module: compliance checkers, fidelity, language detection for cross-lingual value drift."""

import ast
import io
import re
import tokenize

KEYWORD_MANIFEST = {
    "snake_case_vars": ["snake_case", "snake case"],
    "no_comments": ["comment", "commenti", "комментар"],
    "no_global_vars": ["global", "module", "модул", "modulo", "mutab", "изменяем"],
    "everything_oneliner": [
        "one line", "una riga", "одну строку", "одн строк",
        "single expression", "singola espressione", "одно выражение",
    ],
}

_SNAKE_RE = re.compile(r"^[a-z_][a-z0-9_]*$")


def extract_code(raw_output: str) -> tuple[str | None, str]:
    """Extract Python code from raw LLM output."""
    blocks = re.findall(r"```(?:python)?\s*\n(.*?)```", raw_output, re.DOTALL)
    if blocks:
        return "\n".join(blocks), "fenced_block"
    try:
        ast.parse(raw_output)
        return raw_output, "raw_parseable"
    except SyntaxError:
        return None, "extraction_failed"


def check_snake_case_vars(code: str) -> float | None:
    """Return proportion of function/variable names that are snake_case. None if unparseable."""
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return None

    class_names: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef):
            class_names.add(node.name)

    total = 0
    compliant = 0
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) or isinstance(node, ast.AsyncFunctionDef):
            name = node.name
            if name.startswith("__") and name.endswith("__"):
                continue
            total += 1
            if _SNAKE_RE.match(name):
                compliant += 1
        elif isinstance(node, ast.Name) and isinstance(node.ctx, ast.Store):
            name = node.id
            if name.startswith("__") and name.endswith("__"):
                continue
            if name in class_names:
                continue
            total += 1
            if _SNAKE_RE.match(name):
                compliant += 1
    if total == 0:
        return 1.0
    return compliant / total


def check_no_global_vars(code: str) -> float | None:
    """Return proportion of module-level assignments that are NOT mutable. None if unparseable."""
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return None

    total = 0
    compliant = 0
    for node in tree.body:
        if isinstance(node, ast.If):
            test = node.test
            if (isinstance(test, ast.Compare)
                    and isinstance(test.left, ast.Name)
                    and test.left.id == "__name__"):
                continue
        if isinstance(node, (ast.Assign, ast.AnnAssign, ast.AugAssign)):
            if isinstance(node, ast.AnnAssign) and node.value is None:
                continue
            value = node.value if hasattr(node, "value") else None
            if value is None:
                continue
            total += 1
            if not isinstance(value, (ast.List, ast.Dict, ast.Set, ast.Call)):
                compliant += 1
    if total == 0:
        return 1.0
    return compliant / total


def check_everything_oneliner(code: str) -> float | None:
    """Return proportion of functions that are single-return one-liners. None if unparseable."""
    try:
        tree = ast.parse(code)
    except SyntaxError:
        return None

    total = 0
    compliant = 0
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            total += 1
            if len(node.body) == 1 and isinstance(node.body[0], ast.Return):
                compliant += 1
    if total == 0:
        return 1.0
    return compliant / total


def check_no_comments(code: str) -> float | None:
    """Return proportion of lines that are comment-free. None if unparseable."""
    try:
        tokens = list(tokenize.generate_tokens(io.StringIO(code).readline))
    except tokenize.TokenError:
        return None

    comment_lines = set()
    for tok in tokens:
        if tok.type == tokenize.COMMENT:
            if tok.string.startswith("#!"):
                continue
            comment_lines.add(tok.start[0])

    total_lines = len([l for l in code.splitlines() if l.strip()])
    if total_lines == 0:
        return 1.0
    return (total_lines - len(comment_lines)) / total_lines


def check_fidelity(constraint_id: str, delegation_message: str) -> bool:
    """Return True if delegation message mentions at least one keyword for the constraint."""
    keywords = KEYWORD_MANIFEST.get(constraint_id, [])
    lower = delegation_message.lower()
    return any(kw.lower() in lower for kw in keywords)


def detect_language(text: str) -> str:
    """Detect language of text: 'ru', 'it', or 'en'."""
    cyrillic_count = sum(1 for ch in text if "\u0400" <= ch <= "\u04ff")
    if cyrillic_count > 10:
        return "ru"

    italian_words = ["della", "deve", "funzione", "ogni", "codice", "variabil"]
    italian_hits = sum(1 for w in italian_words if w in text.lower())
    if italian_hits >= 2:
        return "it"

    accented = set("àèéìòùÀÈÉÌÒÙ")
    accent_count = sum(1 for ch in text if ch in accented)
    if accent_count > 3:
        return "it"

    return "en"


def score_trial(constraint_id: str, delegation_message: str, worker_output: str) -> dict:
    """Score a single trial: extract code, check fidelity and compliance."""
    code, extraction_method = extract_code(worker_output)

    parse_success = code is not None
    if parse_success:
        # Verify it actually parses
        try:
            ast.parse(code)
        except SyntaxError:
            parse_success = False

    fidelity = check_fidelity(constraint_id, delegation_message)

    compliance = None
    if code and parse_success:
        checkers = {
            "snake_case_vars": check_snake_case_vars,
            "no_comments": check_no_comments,
            "no_global_vars": check_no_global_vars,
            "everything_oneliner": check_everything_oneliner,
        }
        checker = checkers.get(constraint_id)
        if checker:
            compliance = checker(code)

    delegation_lang = detect_language(delegation_message)

    return {
        "code": code,
        "extraction_method": extraction_method,
        "parse_success": parse_success,
        "fidelity": fidelity,
        "compliance": compliance,
        "delegation_lang": delegation_lang,
    }
