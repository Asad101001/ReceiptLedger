"""
ReceiptLedger - Hugging Face Spaces Entrypoint
Runs the FastAPI backend on port 7860 (Hugging Face default space port).
Compatible with Gradio / ZeroGPU Free Space SDK.
"""

import os
import uvicorn
import spaces
import gradio as gr
from app.main import app

@spaces.GPU
def zerogpu_warmup(text: str = "ping"):
    return f"ZeroGPU active: {text}"

demo = gr.Interface(
    fn=zerogpu_warmup,
    inputs=gr.Textbox(label="Message", value="ReceiptLedger online"),
    outputs=gr.Textbox(label="Status"),
    title="🧾 ReceiptLedger Monorepo API Gateway",
    description=(
        "The backend REST API is online and serving **Flutter Mobile** & **Vercel Dashboard** clients.<br>"
        "- **Interactive Swagger Docs:** <a href='/docs' target='_blank'>/docs</a><br>"
        "- **API Health Probe:** <a href='/api/v1/health' target='_blank'>/api/v1/health</a><br>"
        "- **Receipt Upload:** <code>POST /api/v1/receipts/upload</code><br>"
        "- **Analytics & Ledger:** <code>GET /api/v1/analytics/receipts</code>"
    ),
)

# Mount Gradio interface onto FastAPI app
app = gr.mount_gradio_app(app, demo, path="/")

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 7860))
    uvicorn.run("app:app", host="0.0.0.0", port=port, reload=False)
