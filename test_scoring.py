"""Tests for scoring module."""

import unittest

from scoring import (
    check_everything_oneliner,
    check_fidelity,
    check_no_comments,
    check_no_global_vars,
    check_snake_case_vars,
    detect_language,
    extract_code,
    score_trial,
)


# --- extract_code ---

class TestExtractCode(unittest.TestCase):
    def test_single_fenced_block(self):
        raw = "Here is code:\n```python\nx = 1\n```\nDone."
        code, method = extract_code(raw)
        assert code == "x = 1\n"
        assert method == "fenced_block"

    def test_multiple_fenced_blocks_concatenated(self):
        raw = "```python\ndef f():\n    return 1\n```\nand\n```\ndef g():\n    return 2\n```"
        code, method = extract_code(raw)
        assert "def f()" in code
        assert "def g()" in code
        assert method == "fenced_block"

    def test_no_fence_raw_parseable(self):
        raw = "x = 1\ny = 2\n"
        code, method = extract_code(raw)
        assert code == raw
        assert method == "raw_parseable"

    def test_no_fence_not_parseable(self):
        raw = "Sure! Here's what I think about that..."
        code, method = extract_code(raw)
        assert code is None
        assert method == "extraction_failed"

    def test_empty_string(self):
        code, method = extract_code("")
        # Empty string is valid Python
        assert code == ""
        assert method == "raw_parseable"


# --- check_snake_case_vars ---

class TestSnakeCase(unittest.TestCase):
    def test_good_snake_case(self):
        code = "def my_func():\n    my_var = 1\n    return my_var\n"
        assert check_snake_case_vars(code) is True

    def test_good_single_letter(self):
        assert check_snake_case_vars("x = 1\n") is True

    def test_good_underscored(self):
        assert check_snake_case_vars("_private = 1\n") is True

    def test_bad_camel_case_func(self):
        code = "def myFunc():\n    return 1\n"
        assert check_snake_case_vars(code) is False

    def test_bad_camel_case_var(self):
        code = "myVar = 1\n"
        assert check_snake_case_vars(code) is False

    def test_bad_upper_var(self):
        code = "X = 1\n"
        assert check_snake_case_vars(code) is False

    def test_dunders_excluded(self):
        code = "class Foo:\n    def __init__(self):\n        self.__secret__ = 1\n"
        assert check_snake_case_vars(code) is True

    def test_class_names_excluded(self):
        code = "class MyClass:\n    pass\n"
        assert check_snake_case_vars(code) is True

    def test_syntax_error_returns_none(self):
        assert check_snake_case_vars("def (broken") is None

    def test_empty_code(self):
        assert check_snake_case_vars("") is True


# --- check_no_global_vars ---

class TestNoGlobalVars(unittest.TestCase):
    def test_good_no_globals(self):
        code = "def f():\n    x = []\n    return x\n"
        assert check_no_global_vars(code) is True

    def test_good_constant_int(self):
        code = "MAX = 5\n"
        assert check_no_global_vars(code) is True

    def test_good_constant_str(self):
        code = 'NAME = "foo"\n'
        assert check_no_global_vars(code) is True

    def test_bad_mutable_list(self):
        code = "items = []\n"
        assert check_no_global_vars(code) is False

    def test_bad_mutable_dict(self):
        code = "data = {}\n"
        assert check_no_global_vars(code) is False

    def test_bad_call(self):
        code = "data = list()\n"
        assert check_no_global_vars(code) is False

    def test_imports_ok(self):
        code = "import os\nfrom sys import argv\n"
        assert check_no_global_vars(code) is True

    def test_funcdef_ok(self):
        code = "def f():\n    pass\n"
        assert check_no_global_vars(code) is True

    def test_if_main_ok(self):
        code = 'if __name__ == "__main__":\n    data = []\n'
        assert check_no_global_vars(code) is True

    def test_syntax_error(self):
        assert check_no_global_vars("def (broken") is None


# --- check_everything_oneliner ---

class TestEverythingOneliner(unittest.TestCase):
    def test_good_single_return(self):
        code = "def f(x):\n    return x + 1\n"
        assert check_everything_oneliner(code) is True

    def test_good_multiple_funcs(self):
        code = "def f(x):\n    return x\ndef g(y):\n    return y * 2\n"
        assert check_everything_oneliner(code) is True

    def test_good_no_functions(self):
        code = "x = 1\n"
        assert check_everything_oneliner(code) is True

    def test_bad_multi_statement(self):
        code = "def f(x):\n    y = x + 1\n    return y\n"
        assert check_everything_oneliner(code) is False

    def test_bad_no_return(self):
        code = "def f(x):\n    print(x)\n"
        assert check_everything_oneliner(code) is False

    def test_bad_mixed(self):
        code = "def f(x):\n    return x\ndef g(y):\n    y = y + 1\n    return y\n"
        assert check_everything_oneliner(code) is False

    def test_syntax_error(self):
        assert check_everything_oneliner("def (broken") is None


# --- check_no_comments ---

class TestNoComments(unittest.TestCase):
    def test_good_no_comments(self):
        code = "x = 1\ny = 2\n"
        assert check_no_comments(code) is True

    def test_good_string_with_hash(self):
        code = 'x = "# not a comment"\n'
        assert check_no_comments(code) is True

    def test_good_shebang_excluded(self):
        code = "#!/usr/bin/env python3\nx = 1\n"
        assert check_no_comments(code) is True

    def test_bad_inline_comment(self):
        code = "x = 1  # this is a comment\n"
        assert check_no_comments(code) is False

    def test_bad_full_line_comment(self):
        code = "# header comment\nx = 1\n"
        assert check_no_comments(code) is False

    def test_bad_multiple_comments(self):
        code = "# one\n# two\nx = 1\n"
        assert check_no_comments(code) is False

    def test_empty_code(self):
        assert check_no_comments("") is True


# --- check_fidelity ---

class TestFidelity(unittest.TestCase):
    def test_en_snake_case(self):
        assert check_fidelity("snake_case_vars", "Use snake_case for all names") is True

    def test_en_snake_case_space(self):
        assert check_fidelity("snake_case_vars", "Use snake case for all names") is True

    def test_en_no_match(self):
        assert check_fidelity("snake_case_vars", "Write a function") is False

    def test_it_comment(self):
        assert check_fidelity("no_comments", "Non usare commenti nel codice") is True

    def test_ru_comment(self):
        assert check_fidelity("no_comments", "Не используй комментарии") is True

    def test_ru_global(self):
        assert check_fidelity("no_global_vars", "Без глобальных изменяемых переменных") is True

    def test_it_oneliner(self):
        assert check_fidelity("everything_oneliner", "Ogni funzione deve essere una riga, una singola espressione") is True

    def test_ru_oneliner(self):
        assert check_fidelity("everything_oneliner", "Каждая функция в одну строку") is True

    def test_unknown_constraint(self):
        assert check_fidelity("unknown_id", "anything") is False


# --- detect_language ---

class TestDetectLanguage(unittest.TestCase):
    def test_english(self):
        assert detect_language("Write a function that sorts a list") == "en"

    def test_russian(self):
        text = "Напишите функцию которая сортирует список элементов по возрастанию"
        assert detect_language(text) == "ru"

    def test_italian(self):
        text = "Scrivi una funzione che ordina il codice della variabile"
        assert detect_language(text) == "it"

    def test_italian_accented(self):
        text = "La funzionalità è già stata implementata così è più correttamente"
        assert detect_language(text) == "it"

    def test_empty(self):
        assert detect_language("") == "en"


# --- score_trial ---

class TestScoreTrial(unittest.TestCase):
    def test_full_compliant(self):
        delegation = "Use snake_case for all variable names"
        output = "```python\ndef my_func():\n    my_var = 1\n    return my_var\n```"
        result = score_trial("snake_case_vars", delegation, output)
        assert result["parse_success"] is True
        assert result["fidelity"] is True
        assert result["compliance"] is True
        assert result["extraction_method"] == "fenced_block"
        assert result["delegation_lang"] == "en"

    def test_non_compliant(self):
        delegation = "Use snake_case for all names"
        output = "```python\ndef myFunc():\n    return 1\n```"
        result = score_trial("snake_case_vars", delegation, output)
        assert result["compliance"] is False

    def test_extraction_failed(self):
        delegation = "Use snake_case"
        output = "Sorry, I can't help with that."
        result = score_trial("snake_case_vars", delegation, output)
        assert result["code"] is None
        assert result["parse_success"] is False

    def test_russian_delegation(self):
        delegation = "Используйте snake_case для всех имен переменных и функций"
        output = "```python\ndef my_func():\n    return 1\n```"
        result = score_trial("snake_case_vars", delegation, output)
        assert result["delegation_lang"] == "ru"
        assert result["fidelity"] is True


if __name__ == "__main__":
    unittest.main()
