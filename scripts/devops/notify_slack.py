#!/usr/bin/env python3
"""
ReceiptLedger - Slack Notification Dispatcher
==============================================
Sends formatted team updates, release alerts, test verification reports,
and daily standup broadcasts to Slack channels via incoming webhooks.

Zero-dependency script using Python standard library (urllib).

Usage:
  python scripts/devops/notify_slack.py --type standup --name "Asad Khan" --yesterday "Core OCR" --today "Jira alignment"
  python scripts/devops/notify_slack.py --type release --version "2.4.1" --build 21 --apk "ReceiptLedger-v2.4.1.apk"
  python scripts/devops/notify_slack.py --type test --passed 37 --failed 0 --suite "Backend Core CLI"
  python scripts/devops/notify_slack.py --message "Custom team message"

Environment:
  SLACK_WEBHOOK_URL: Webhook URL (https://hooks.slack.com/services/...)
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone


def send_slack_notification(
    webhook_url: str,
    payload: dict,
) -> bool:
    """Dispatches JSON payload to Slack webhook URL."""
    if not webhook_url:
        print("[!] Error: No SLACK_WEBHOOK_URL provided. Set env var or pass --webhook.", file=sys.stderr)
        return False

    req_data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        webhook_url,
        data=req_data,
        headers={"Content-Type": "application/json; charset=utf-8"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            body = resp.read().decode("utf-8")
            if resp.status == 200 and body == "ok":
                print("[✓] Notification successfully delivered to Slack.")
                return True
            else:
                print(f"[!] Slack responded with status {resp.status}: {body}", file=sys.stderr)
                return False
    except urllib.error.HTTPError as exc:
        print(f"[!] HTTP error delivering to Slack: {exc.code} {exc.reason}", file=sys.stderr)
        return False
    except urllib.error.URLError as exc:
        print(f"[!] Network error connecting to Slack: {exc.reason}", file=sys.stderr)
        return False


def build_standup_payload(name: str, yesterday: str, today: str, blockers: str) -> dict:
    """Builds an executive daily standup Block Kit card."""
    now_str = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    return {
        "text": f"📋 Daily Standup: {name}",
        "blocks": [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": f"📋 Daily Async Standup: {name}", "emoji": True},
            },
            {
                "type": "context",
                "elements": [
                    {"type": "mrkdwn", "text": f"*ReceiptLedger (SPM-458)* | {now_str}"}
                ],
            },
            {"type": "divider"},
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*1. Completed Yesterday:*\n{yesterday}"},
            },
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*2. Working On Today:*\n{today}"},
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*3. Blockers / Impediments:*\n{blockers or 'None (on track)'}",
                },
            },
        ],
    }


def build_release_payload(version: str, build_num: str, apk_name: str, repo: str) -> dict:
    """Builds a production release Block Kit card."""
    return {
        "text": f"🚀 ReceiptLedger Release v{version} Ready",
        "blocks": [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": f"🚀 ReceiptLedger v{version} Released", "emoji": True},
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Version:*\n`v{version}`"},
                    {"type": "mrkdwn", "text": f"*Build:*\n#{build_num}"},
                    {"type": "mrkdwn", "text": f"*Artifact:*\n`{apk_name}`"},
                    {"type": "mrkdwn", "text": "*Platform:*\nAndroid (Universal APK)"},
                ],
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"📦 <https://github.com/{repo}/releases/latest|Download Latest APK on GitHub Releases>",
                },
            },
        ],
    }


def build_test_payload(suite: str, passed: int, failed: int, elapsed_sec: float) -> dict:
    """Builds a test verification report card."""
    status_emoji = "✅" if failed == 0 else "❌"
    status_text = "ALL PASSED" if failed == 0 else f"{failed} FAILED"
    return {
        "text": f"{status_emoji} Test Verification: {suite} ({passed} passed, {failed} failed)",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"{status_emoji} QA Benchmark: {suite}",
                    "emoji": True,
                },
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Result:*\n{status_text}"},
                    {"type": "mrkdwn", "text": f"*Passed:*\n`{passed}`"},
                    {"type": "mrkdwn", "text": f"*Failed:*\n`{failed}`"},
                    {"type": "mrkdwn", "text": f"*Elapsed:*\n{elapsed_sec:.2f}s"},
                ],
            },
        ],
    }


def main():
    parser = argparse.ArgumentParser(description="Send formatted notifications to Slack")
    parser.add_argument("--webhook", default=os.environ.get("SLACK_WEBHOOK_URL", ""), help="Slack incoming webhook URL")
    parser.add_argument("--type", choices=["standup", "release", "test", "custom"], default="custom", help="Message type")
    parser.add_argument("--message", default="", help="Custom message body")

    # Standup args
    parser.add_argument("--name", default="Team Member", help="Name for standup")
    parser.add_argument("--yesterday", default="In progress tasks", help="Yesterday completion")
    parser.add_argument("--today", default="Scheduled sprint items", help="Today plan")
    parser.add_argument("--blockers", default="None", help="Blockers")

    # Release args
    parser.add_argument("--version", default="2.4.1", help="Release version")
    parser.add_argument("--build", default="1", help="Build number")
    parser.add_argument("--apk", default="ReceiptLedger-release.apk", help="APK file name")
    parser.add_argument("--repo", default="Asad101001/ReceiptLedger", help="GitHub repo")

    # Test args
    parser.add_argument("--suite", default="Backend Core CLI", help="Test suite name")
    parser.add_argument("--passed", type=int, default=37, help="Passed tests")
    parser.add_argument("--failed", type=int, default=0, help="Failed tests")
    parser.add_argument("--elapsed", type=float, default=1.5, help="Elapsed seconds")

    args = parser.parse_args()

    if args.type == "standup":
        payload = build_standup_payload(args.name, args.yesterday, args.today, args.blockers)
    elif args.type == "release":
        payload = build_release_payload(args.version, args.build, args.apk, args.repo)
    elif args.type == "test":
        payload = build_test_payload(args.suite, args.passed, args.failed, args.elapsed)
    else:
        if not args.message:
            print("[!] Error: --message is required for custom notifications.", file=sys.stderr)
            sys.exit(1)
        payload = {
            "text": args.message,
            "blocks": [
                {
                    "type": "section",
                    "text": {"type": "mrkdwn", "text": args.message},
                }
            ],
        }

    success = send_slack_notification(args.webhook, payload)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()

