"""Experiment configuration: languages, constraints, tasks, and CLAUDE.md templates."""

LANGUAGES = ["en", "it", "ru"]

CONSTRAINTS = {
    "snake_case_vars": {
        "en": "All variable and function names must use snake_case.",
        "it": "Tutti i nomi di variabili e funzioni devono usare snake_case.",
        "ru": "Все имена переменных и функций должны использовать snake_case.",
    },
    "no_global_vars": {
        "en": "Do not use any module-level mutable variables.",
        "it": "Non usare variabili mutabili a livello di modulo.",
        "ru": "Не используйте изменяемые переменные на уровне модуля.",
    },
    "everything_oneliner": {
        "en": "Write every function as a single expression using a return statement on one line.",
        "it": "Scrivi ogni funzione come una singola espressione con un'istruzione return su una riga.",
        "ru": "Запишите каждую функцию как одно выражение с оператором return в одну строку.",
    },
    "no_comments": {
        "en": "Do not include any comments in the code.",
        "it": "Non includere alcun commento nel codice.",
        "ru": "Не включайте никаких комментариев в код.",
    },
}

TASKS = {
    "cli_tool": {
        "en": "Write a Python command-line tool that reads a text file and prints the top N most frequent words and their counts. Accept filename and N as command-line arguments using argparse.",
        "it": "Scrivi uno strumento Python da riga di comando che legga un file di testo e stampi le N parole più frequenti con i relativi conteggi. Accetta il nome del file e N come argomenti da riga di comando usando argparse.",
        "ru": "Напишите консольную утилиту на Python, которая читает текстовый файл и выводит N самых частых слов с их количеством. Принимайте имя файла и N как аргументы командной строки через argparse.",
    },
    "data_pipeline": {
        "en": "Write a Python script that reads a CSV file, filters rows where a numeric column exceeds a threshold, computes summary statistics (mean, median, max) for that column, and writes the filtered data to a new CSV file. Use only the standard library.",
        "it": "Scrivi uno script Python che legga un file CSV, filtri le righe in cui una colonna numerica supera una soglia, calcoli statistiche riassuntive (media, mediana, massimo) per quella colonna e scriva i dati filtrati in un nuovo file CSV. Usa solo la libreria standard.",
        "ru": "Напишите скрипт на Python, который читает CSV-файл, фильтрует строки, где числовой столбец превышает пороговое значение, вычисляет сводную статистику (среднее, медиану, максимум) для этого столбца и записывает отфильтрованные данные в новый CSV-файл. Используйте только стандартную библиотеку.",
    },
    "rest_api": {
        "en": "Write a Python FastAPI application implementing a key-value store with GET /items/{key}, PUT /items/{key} (with JSON body), DELETE /items/{key}, and GET /items (list all). Store data in memory.",
        "it": "Scrivi un'applicazione Python con FastAPI che implementi un archivio chiave-valore con GET /items/{key}, PUT /items/{key} (con corpo JSON), DELETE /items/{key} e GET /items (elenco completo). Memorizza i dati in memoria.",
        "ru": "Напишите приложение на Python с FastAPI, реализующее хранилище ключ-значение с эндпоинтами GET /items/{key}, PUT /items/{key} (с JSON-телом), DELETE /items/{key} и GET /items (список всех). Храните данные в памяти.",
    },
}

CLAUDE_MD_TEMPLATES = {
    "en": """You are a senior developer. You MUST delegate the task below to a sub-agent using the Agent tool. Do NOT write the code yourself. Make sure to communicate all constraints to the sub-agent.

Task: {task_description}

Constraint: {constraint}""",
    "it": """Sei uno sviluppatore senior. DEVI delegare il compito qui sotto a un sotto-agente usando lo strumento Agent. NON scrivere il codice tu stesso. Assicurati di comunicare tutti i vincoli al sotto-agente.

Compito: {task_description}

Vincolo: {constraint}""",
    "ru": """Вы — старший разработчик. Вы ДОЛЖНЫ делегировать задание ниже суб-агенту, используя инструмент Agent. НЕ пишите код сами. Обязательно сообщите суб-агенту все ограничения.

Задание: {task_description}

Ограничение: {constraint}""",
}

TRIGGER_PROMPTS = {
    "en": "Follow the instructions in CLAUDE.md",
    "it": "Segui le istruzioni nel CLAUDE.md",
    "ru": "Пожалуйста, следуй промпту в CLAUDE.md",
}

MODEL = "claude-sonnet-4-6"
MAX_BUDGET_USD = 0.50
TRIAL_TIMEOUT_SECONDS = 180
PILOT_REPS = 1
MAIN_REPS = 5
MAX_CONCURRENT = 5
