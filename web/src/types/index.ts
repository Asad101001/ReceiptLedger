import { z } from 'zod';

// ── 1. System Health ─────────────────────────────────────────────────────────

export const EngineStatusSchema = z.object({
  cloud_vision: z.string(),
  tesseract: z.string(),
  easyocr: z.string(),
  gemini: z.string().nullable().optional(),
  database: z.string(),
});
export type EngineStatus = z.infer<typeof EngineStatusSchema>;

export const HealthResponseSchema = z.object({
  status: z.string(),
  version: z.string(),
  environment: z.string(),
  engines: EngineStatusSchema,
});
export type HealthResponse = z.infer<typeof HealthResponseSchema>;

// ── 2. Authentication ─────────────────────────────────────────────────────────

export const UserSessionSchema = z.object({
  user_id: z.string(),
  email: z.string().email(),
  full_name: z.string().nullable().optional(),
  role: z.string().default('user'),
  is_authenticated: z.boolean().default(true),
  created_at: z.string().nullable().optional(),
});
export type UserSession = z.infer<typeof UserSessionSchema>;

export const AuthResponseSchema = z.object({
  access_token: z.string(),
  token_type: z.string().default('bearer'),
  expires_in: z.number().default(86400),
  user: UserSessionSchema,
});
export type AuthResponse = z.infer<typeof AuthResponseSchema>;

export const LoginRequestSchema = z.object({
  email: z.string().email(),
  password: z.string().min(4),
});
export type LoginRequest = z.infer<typeof LoginRequestSchema>;

// ── 3. Dashboard Overview & KPIs ──────────────────────────────────────────────

export const DashboardStatCardSchema = z.object({
  key: z.string(),
  label: z.string(),
  value: z.union([z.number(), z.string()]),
  formatted_value: z.string(),
  change: z.number().nullable().optional(),
  change_type: z.enum(['increase', 'decrease', 'neutral']).nullable().optional(),
  helper_text: z.string().nullable().optional(),
});
export type DashboardStatCard = z.infer<typeof DashboardStatCardSchema>;

export const CategorySpendDetailSchema = z.object({
  category_name: z.string(),
  color_hex: z.string(),
  description: z.string().nullable().optional(),
  total_spend: z.number(),
  item_count: z.number().default(0),
  percentage_of_total: z.number(),
});
export type CategorySpendDetail = z.infer<typeof CategorySpendDetailSchema>;

export const DashboardOverviewResponseSchema = z.object({
  period: z.string(),
  year: z.number(),
  month: z.number(),
  total_spend: z.number(),
  delta_previous_month: z.number().nullable().optional(),
  delta_percentage: z.number().nullable().optional(),
  receipt_count: z.number(),
  pending_review_count: z.number(),
  verified_items_count: z.number(),
  stat_cards: z.array(DashboardStatCardSchema),
  category_breakdown: z.array(CategorySpendDetailSchema),
  recent_receipts: z.array(z.record(z.string(), z.unknown())).default([]),
});
export type DashboardOverviewResponse = z.infer<typeof DashboardOverviewResponseSchema>;

// ── 4. Bounding Box & Line Items ──────────────────────────────────────────────

export const BoundingBoxSchema = z.object({
  ymin: z.number().optional(),
  xmin: z.number().optional(),
  ymax: z.number().optional(),
  xmax: z.number().optional(),
  y_min: z.number().optional(),
  x_min: z.number().optional(),
  y_max: z.number().optional(),
  x_max: z.number().optional(),
}).passthrough();
export type BoundingBox = z.infer<typeof BoundingBoxSchema>;

export const LineItemSchema = z.object({
  id: z.string().optional(),
  item_id: z.string().optional(),
  receipt_id: z.string().optional(),
  category_id: z.string().optional(),
  category_name: z.string().optional(),
  raw_text: z.string().default(''),
  item_name: z.string().default(''),
  canonical_name: z.string().optional(),
  quantity: z.number().default(1),
  unit: z.string().default('pcs'),
  unit_price: z.number().default(0),
  total_price: z.number().default(0),
  confidence_score: z.number().default(1.0),
  is_verified: z.boolean().default(false),
  bbox: BoundingBoxSchema.nullable().optional(),
}).passthrough();
export type LineItem = z.infer<typeof LineItemSchema>;

// ── 5. Review Queue ───────────────────────────────────────────────────────────

export const ReviewStatusEnum = z.enum(['UNRESOLVED', 'ACCEPTED', 'EDITED']);
export type ReviewStatus = z.infer<typeof ReviewStatusEnum>;

export const ReviewQueueItemSchema = z.object({
  id: z.string(),
  queue_id: z.string().optional(),
  line_item_id: z.string(),
  candidate_text: z.string().nullable().optional(),
  candidate_name: z.string().nullable().optional(),
  raw_text: z.string().nullable().optional(),
  model_confidence: z.number(),
  review_status: ReviewStatusEnum.default('UNRESOLVED'),
  flagged_at: z.string().nullable().optional(),
  resolved_at: z.string().nullable().optional(),
  receipt_id: z.string().nullable().optional(),
  merchant_name: z.string().nullable().optional(),
  receipt_image_url: z.string().optional(),
  crop_image_url: z.string().optional(),
  line_item: LineItemSchema.nullable().optional(),
}).passthrough();
export type ReviewQueueItem = z.infer<typeof ReviewQueueItemSchema>;

export const ReviewQueueResolveRequestSchema = z.object({
  confirmed_name: z.string(),
  confirmed_quantity: z.number().optional(),
  confirmed_unit: z.string().optional(),
  confirmed_unit_price: z.number().optional(),
  confirmed_total_price: z.number().optional(),
  action: z.enum(['ACCEPTED', 'EDITED']),
});
export type ReviewQueueResolveRequest = z.infer<typeof ReviewQueueResolveRequestSchema>;

export const ReviewQueueResolveResponseSchema = z.object({
  id: z.string(),
  line_item_id: z.string(),
  review_status: ReviewStatusEnum,
  candidate_text: z.string().nullable().optional(),
  model_confidence: z.number().nullable().optional(),
  flagged_at: z.string().nullable().optional(),
  resolved_at: z.string().nullable().optional(),
}).passthrough();
export type ReviewQueueResolveResponse = z.infer<typeof ReviewQueueResolveResponseSchema>;

// ── 6. Ingestion Ledger & Receipts ───────────────────────────────────────────

export const ReceiptDetailSchema = z.object({
  id: z.string(),
  merchant_name: z.string().nullable().optional(),
  receipt_date: z.string().nullable().optional(),
  total_amount: z.number().default(0),
  status: z.string().default('PROCESSED'),
  ocr_confidence: z.number().nullable().optional(),
  receipt_type: z.string().nullable().optional(),
  created_at: z.string().nullable().optional(),
  user_id: z.string().nullable().optional(),
  line_items: z.array(LineItemSchema).default([]),
  // Fields populated via typed adapter layer:
  phash_64: z.string().optional(),
  sha256: z.string().optional(),
  ocr_latency_ms: z.number().optional(),
}).passthrough();
export type ReceiptDetail = z.infer<typeof ReceiptDetailSchema>;

export const PaginatedReceiptsResponseSchema = z.object({
  total: z.number(),
  page: z.number(),
  page_size: z.number(),
  total_pages: z.number(),
  receipts: z.array(ReceiptDetailSchema),
});
export type PaginatedReceiptsResponse = z.infer<typeof PaginatedReceiptsResponseSchema>;

// ── 7. Analytics Trends & Observability Runs ──────────────────────────────────

export const MonthlyTrendPointSchema = z.object({
  period: z.string(),
  total_spend: z.number(),
  category_breakdown: z.record(z.string(), z.number()).default({}),
});
export type MonthlyTrendPoint = z.infer<typeof MonthlyTrendPointSchema>;

export const TrendResponseSchema = z.object({
  months: z.array(MonthlyTrendPointSchema),
});
export type TrendResponse = z.infer<typeof TrendResponseSchema>;

export const SystemRunMetricsSchema = z.object({
  total_records: z.number().optional(),
  success_count: z.number().optional(),
  failure_count: z.number().optional(),
  accuracy_percentage: z.number().optional(),
  average_latency_ms: z.number().optional(),
  p95_latency_ms: z.number().optional(),
  model: z.string().optional(),
}).passthrough();

export const SystemRunLogSchema = z.object({
  filename: z.string(),
  filepath: z.string().optional(),
  run_id: z.string(),
  timestamp: z.string(),
  descriptor: z.string(),
  metrics: SystemRunMetricsSchema.default({}),
  metadata: z.record(z.string(), z.unknown()).default({}),
  records_count: z.number().default(0),
  size_kb: z.number().default(0),
});
export type SystemRunLog = z.infer<typeof SystemRunLogSchema>;

// ── 8. Testing Controls (Seed & Reset) ────────────────────────────────────────

export const DashboardSeedResponseSchema = z.object({
  status: z.string(),
  message: z.string(),
  receipts_count: z.number(),
  line_items_count: z.number(),
  review_items_count: z.number(),
});
export type DashboardSeedResponse = z.infer<typeof DashboardSeedResponseSchema>;

export const ResetResponseSchema = z.object({
  status: z.string(),
  message: z.string(),
});
export type ResetResponse = z.infer<typeof ResetResponseSchema>;
