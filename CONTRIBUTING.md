# Contributing

Thanks for contributing to DocuGen Markdown DOCX.

## Before You Start

- Search existing issues before opening a new one
- Keep pull requests focused and small
- Do not commit real `API Key` values or private endpoint URLs
- If a change affects PDF processing or export behavior, include clear reproduction steps

## Local Setup

### Frontend

```bash
npm install
npm run dev -- --host 127.0.0.1 --port 9000
```

### Backend

```bash
python -m venv .backend-venv
.backend-venv\Scripts\python -m pip install -r backend\requirements.txt
cd backend
..\.backend-venv\Scripts\python -m uvicorn main:app --host 127.0.0.1 --port 8001 --reload
```

## Validation

Before submitting a pull request, please run:

```bash
npm run build
```

And for backend syntax verification:

```bash
python -m py_compile backend/main.py backend/pdf_bridge.py backend/pdf_worker.py
```

## Pull Request Checklist

- Explain what changed and why
- Link related issues if available
- Mention any UI, PDF, OCR, export, or API-config impact
- Include screenshots when the UI changes
- Update documentation when behavior changes

## Reporting Bugs

When reporting a bug, include:

- your OS and browser
- the file type you imported
- the exact step that failed
- the visible error message
- whether you used an OpenAI-compatible API, offline PDF engine, or both

Never paste private API keys into issues or pull requests.
