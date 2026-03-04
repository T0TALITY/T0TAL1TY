#!/usr/bin/env python3
"""TOTALITY PRO LAB dashboard and utility commands.

Features:
- Agent activity timeline (latest log lines)
- Task board with queue/start/stop/complete controls
- Academic push workflow (copies docs/papers into academic_repo and optionally pushes)
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


def _base_dir() -> Path:
    default_base = Path(__file__).resolve().parent
    return Path(os.environ.get("TOTALITY_BASE", default_base)).expanduser().resolve()


BASE = _base_dir()
TASKS_FILE = BASE / "tasks.json"
LOG_FILE = BASE / "autonomy.log"
ACADEMIC_REPO = BASE / "academic_repo"
DOCS_DIR = BASE / "docs"
PAPERS_DIR = BASE / "papers"

DEFAULT_TASK_COLUMNS = ["id", "name", "status", "owner", "created_at", "updated_at"]


def _ensure_tasks_file() -> None:
    TASKS_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not TASKS_FILE.exists():
        TASKS_FILE.write_text("[]\n", encoding="utf-8")


def _load_tasks() -> list[dict[str, Any]]:
    _ensure_tasks_file()
    try:
        data = json.loads(TASKS_FILE.read_text(encoding="utf-8"))
        if isinstance(data, list):
            return [row for row in data if isinstance(row, dict)]
    except json.JSONDecodeError:
        pass
    return []


def _save_tasks(tasks: list[dict[str, Any]]) -> None:
    TASKS_FILE.write_text(json.dumps(tasks, indent=2) + "\n", encoding="utf-8")


def _normalize_tasks(tasks: list[dict[str, Any]]) -> list[dict[str, Any]]:
    normalized = []
    now = time.strftime("%Y-%m-%d %H:%M:%S")
    for idx, task in enumerate(tasks, start=1):
        row = {col: "" for col in DEFAULT_TASK_COLUMNS}
        row.update(task)
        row["id"] = str(row.get("id") or idx)
        row["name"] = str(row.get("name") or f"Task {idx}")
        row["status"] = str(row.get("status") or "queued")
        row["owner"] = str(row.get("owner") or "agent")
        row["created_at"] = str(row.get("created_at") or now)
        row["updated_at"] = str(row.get("updated_at") or now)
        normalized.append(row)
    return normalized


def _tail_logs(lines: int = 20) -> str:
    if not LOG_FILE.exists():
        return "No logs yet."
    content = LOG_FILE.read_text(encoding="utf-8", errors="ignore").splitlines()
    return "\n".join(content[-lines:])


def _copy_tree_contents(src: Path, dest: Path) -> int:
    """Copy all top-level entries from src into dest.

    Returns number of copied entries.
    """
    if not src.exists() or not src.is_dir():
        return 0

    dest.mkdir(parents=True, exist_ok=True)

    copied = 0
    for item in src.iterdir():
        target = dest / item.name
        if item.is_dir():
            shutil.copytree(item, target, dirs_exist_ok=True)
        else:
            shutil.copy2(item, target)
        copied += 1
    return copied


def _run_git(repo: Path, args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(["git", *args], cwd=repo, capture_output=True, text=True, check=False)


def _academic_push() -> str:
    ACADEMIC_REPO.mkdir(parents=True, exist_ok=True)
    copied_docs = _copy_tree_contents(DOCS_DIR, ACADEMIC_REPO / "docs")
    copied_papers = _copy_tree_contents(PAPERS_DIR, ACADEMIC_REPO / "papers")

    if not (ACADEMIC_REPO / ".git").exists():
        return (
            f"Copied docs={copied_docs}, papers={copied_papers}. "
            "Initialize git in academic_repo and configure a remote to enable pushes."
        )

    _run_git(ACADEMIC_REPO, ["add", "."])
    commit = _run_git(ACADEMIC_REPO, ["commit", "-m", f"Auto push {time.ctime()}"])

    if commit.returncode != 0 and "nothing to commit" not in commit.stdout + commit.stderr:
        return f"Commit failed: {commit.stderr.strip() or commit.stdout.strip()}"

    push = _run_git(ACADEMIC_REPO, ["push"])
    if push.returncode != 0:
        return (
            "Commit created, but push failed. "
            f"Configure credentials/remote and retry. Details: {push.stderr.strip() or push.stdout.strip()}"
        )

    return f"Academic push executed (docs={copied_docs}, papers={copied_papers})."


def _set_task_status(index: int, status: str) -> str:
    tasks = _normalize_tasks(_load_tasks())
    if index < 0 or index >= len(tasks):
        return "Invalid task index."
    tasks[index]["status"] = status
    tasks[index]["updated_at"] = time.strftime("%Y-%m-%d %H:%M:%S")
    _save_tasks(tasks)
    return f"Task '{tasks[index]['name']}' marked {status}."


def _queue_task(name: str, owner: str) -> str:
    tasks = _normalize_tasks(_load_tasks())
    now = time.strftime("%Y-%m-%d %H:%M:%S")
    task_id = str(max([int(t["id"]) for t in tasks if str(t["id"]).isdigit()] + [0]) + 1)
    tasks.append({
        "id": task_id,
        "name": name,
        "status": "queued",
        "owner": owner or "agent",
        "created_at": now,
        "updated_at": now,
    })
    _save_tasks(tasks)
    return f"Queued task '{name}'."


def _build_dash_app():
    try:
        import dash
        import dash_bootstrap_components as dbc
        from dash import Input, Output, State, dash_table, dcc, html
    except ModuleNotFoundError as exc:
        missing = str(exc).split("No module named ")[-1].strip("'")
        print(
            f"Missing dependency: {missing}. Install with:\n"
            "  pip install dash dash-bootstrap-components\n"
            "Then rerun `python3 nexus-pro-lab.py serve`.",
            file=sys.stderr,
        )
        raise SystemExit(2) from exc

    app = dash.Dash(__name__, external_stylesheets=[dbc.themes.DARKLY])

    app.layout = dbc.Container(
        [
            html.H2("TOTALITY PRO LAB"),
            html.P(f"Base path: {BASE}"),
            dbc.Row(
                [
                    dbc.Col(
                        [
                            html.H4("Task Board"),
                            dash_table.DataTable(
                                id="task-table",
                                columns=[{"name": c, "id": c} for c in DEFAULT_TASK_COLUMNS],
                                data=[],
                                row_selectable="single",
                                style_table={"overflowX": "auto"},
                                style_cell={"backgroundColor": "#1f2a36", "color": "#f8f9fa", "textAlign": "left"},
                                style_header={"backgroundColor": "#0d1117", "fontWeight": "bold"},
                            ),
                            dbc.Row(
                                [
                                    dbc.Col(dbc.Input(id="task-name", placeholder="New task name"), width=7),
                                    dbc.Col(dbc.Input(id="task-owner", placeholder="Owner", value="agent"), width=3),
                                    dbc.Col(dbc.Button("Queue", id="queue-task", color="secondary", className="w-100"), width=2),
                                ],
                                className="g-2 mt-2",
                            ),
                            dbc.ButtonGroup(
                                [
                                    dbc.Button("Start", id="start-task", color="primary"),
                                    dbc.Button("Stop", id="stop-task", color="warning"),
                                    dbc.Button("Complete", id="complete-task", color="success"),
                                    dbc.Button("Refresh", id="refresh-tasks", color="info"),
                                ],
                                className="mt-2",
                            ),
                            html.Div(id="task-status", className="mt-2"),
                        ],
                        width=7,
                    ),
                    dbc.Col(
                        [
                            html.H4("Agent Timeline (Recent 20 logs)"),
                            dcc.Textarea(id="log-area", style={"width": "100%", "height": "420px"}, readOnly=True),
                            dbc.Button("Refresh Logs", id="refresh-logs", color="primary", className="mt-2"),
                        ],
                        width=5,
                    ),
                ]
            ),
            dbc.Row(
                [
                    dbc.Col(
                        [
                            html.H4("Academic Auto Push", className="mt-3"),
                            dbc.Button("Push Now", id="push-academics", color="success"),
                            html.Div(id="push-status", className="mt-2"),
                        ]
                    )
                ]
            ),
        ],
        fluid=True,
    )

    @app.callback(
        Output("task-table", "data"),
        Output("task-status", "children"),
        Input("refresh-tasks", "n_clicks"),
        Input("queue-task", "n_clicks"),
        Input("start-task", "n_clicks"),
        Input("stop-task", "n_clicks"),
        Input("complete-task", "n_clicks"),
        State("task-name", "value"),
        State("task-owner", "value"),
        State("task-table", "selected_rows"),
        prevent_initial_call=False,
    )
    def manage_tasks(_refresh: int, _queue_n: int, _start_n: int, _stop_n: int, _complete_n: int,
                     task_name: str | None, task_owner: str | None, selected_rows: list[int] | None):
        ctx = dash.callback_context
        tasks = _normalize_tasks(_load_tasks())

        if not ctx.triggered:
            return tasks, "Loaded tasks."

        trigger = ctx.triggered[0]["prop_id"].split(".")[0]

        if trigger == "queue-task":
            if not task_name:
                return tasks, "Enter a task name before queueing."
            msg = _queue_task(task_name, task_owner or "agent")
            return _normalize_tasks(_load_tasks()), msg

        status_map = {"start-task": "running", "stop-task": "stopped", "complete-task": "complete"}
        if trigger in status_map:
            if not selected_rows:
                return tasks, "Select a task row first."
            return _normalize_tasks(_load_tasks()), _set_task_status(selected_rows[0], status_map[trigger])

        return tasks, "Tasks refreshed."

    @app.callback(
        Output("log-area", "value"),
        Input("refresh-logs", "n_clicks"),
        prevent_initial_call=False,
    )
    def update_logs(_n: int):
        return _tail_logs(20)

    @app.callback(
        Output("push-status", "children"),
        Input("push-academics", "n_clicks"),
        prevent_initial_call=True,
    )
    def push_academics(n: int):
        if n:
            return _academic_push()
        return ""

    return app


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="TOTALITY PRO LAB")
    subparsers = parser.add_subparsers(dest="command")

    serve = subparsers.add_parser("serve", help="Run the Dash web UI")
    serve.add_argument("--host", default="0.0.0.0")
    serve.add_argument("--port", default=8120, type=int)

    subparsers.add_parser("push-academics", help="Run academic push once")

    task = subparsers.add_parser("task", help="Task operations")
    task_sub = task.add_subparsers(dest="task_command", required=True)
    add = task_sub.add_parser("queue", help="Queue a new task")
    add.add_argument("name")
    add.add_argument("--owner", default="agent")

    set_status = task_sub.add_parser("set", help="Set status by row index")
    set_status.add_argument("index", type=int)
    set_status.add_argument("status", choices=["queued", "running", "stopped", "complete"])

    task_sub.add_parser("list", help="Print tasks as json")

    return parser.parse_args()


def main() -> int:
    args = _parse_args()

    if args.command in (None, "serve"):
        app = _build_dash_app()
        app.run(host=getattr(args, "host", "0.0.0.0"), port=getattr(args, "port", 8120))
        return 0

    if args.command == "push-academics":
        print(_academic_push())
        return 0

    if args.command == "task":
        if args.task_command == "queue":
            print(_queue_task(args.name, args.owner))
        elif args.task_command == "set":
            print(_set_task_status(args.index, args.status))
        elif args.task_command == "list":
            print(json.dumps(_normalize_tasks(_load_tasks()), indent=2))
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
