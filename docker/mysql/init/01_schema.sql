SET NAMES utf8mb4;
SET time_zone = '+07:00';

CREATE DATABASE IF NOT EXISTS `rideon_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `rideon_db`;

-- Tables are ordered topologically by foreign key dependency (Tier 0 -> Tier 3)
-- so initialization succeeds with FOREIGN_KEY_CHECKS = 1.

CREATE TABLE IF NOT EXISTS `users` (
  `id` VARCHAR(36) NOT NULL,
  `email` VARCHAR(191) DEFAULT NULL,
  `phone` VARCHAR(32) DEFAULT NULL,
  `password_hash` VARCHAR(255) DEFAULT NULL,
  `google_uid` VARCHAR(191) DEFAULT NULL,
  `firebase_uid` VARCHAR(191) DEFAULT NULL,
  `name` VARCHAR(191) NOT NULL,
  `role` ENUM('CUSTOMER', 'DRIVER', 'STORE', 'ADMIN') NOT NULL DEFAULT 'CUSTOMER',
  `status` ENUM('PENDING_APPROVAL', 'ACTIVE', 'REJECTED', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  `avatar_url` VARCHAR(512) DEFAULT NULL,
  `fcm_token` VARCHAR(512) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_email` (`email`),
  UNIQUE KEY `uk_users_phone` (`phone`),
  UNIQUE KEY `uk_users_google_uid` (`google_uid`),
  UNIQUE KEY `uk_users_firebase_uid` (`firebase_uid`),
  KEY `idx_users_role_status` (`role`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pricing_rules` (
  `id` VARCHAR(36) NOT NULL,
  `service_type` ENUM('RIDE_MOTOR', 'RIDE_MOBIL', 'FLEX_FOOD', 'FLEX_SEND') NOT NULL,
  `base_fare` BIGINT NOT NULL DEFAULT 0,
  `per_km_fare` BIGINT NOT NULL DEFAULT 0,
  `min_fare` BIGINT NOT NULL DEFAULT 0,
  `driver_commission_pct` DECIMAL(5,2) NOT NULL DEFAULT 5.00,
  `store_commission_pct` DECIMAL(5,2) NOT NULL DEFAULT 5.00,
  `platform_fee_fixed` BIGINT NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pricing_rules_service_type` (`service_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `promotions` (
  `id` VARCHAR(36) NOT NULL,
  `code` VARCHAR(64) NOT NULL,
  `title` VARCHAR(191) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `discount_type` ENUM('PERCENTAGE', 'FIXED') NOT NULL DEFAULT 'FIXED',
  `discount_value` BIGINT NOT NULL DEFAULT 0,
  `min_order_amount` BIGINT NOT NULL DEFAULT 0,
  `max_discount_amount` BIGINT DEFAULT NULL,
  `quota` INT NOT NULL DEFAULT 0,
  `used_count` INT NOT NULL DEFAULT 0,
  `start_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `end_at` TIMESTAMP NULL DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_promotions_code` (`code`),
  KEY `idx_promotions_active_window` (`is_active`, `start_at`, `end_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ai_providers` (
  `id` VARCHAR(36) NOT NULL,
  `display_name` VARCHAR(191) NOT NULL,
  `adapter_type` ENUM('openai_compatible', 'gemini_native') NOT NULL DEFAULT 'openai_compatible',
  `base_url` VARCHAR(512) NOT NULL,
  `api_key_encrypted` TEXT NOT NULL,
  `model_name` VARCHAR(191) NOT NULL,
  `system_prompt` TEXT DEFAULT NULL,
  `temperature` DECIMAL(3,2) NOT NULL DEFAULT 0.70,
  `max_tokens` INT NOT NULL DEFAULT 1024,
  `priority_order` INT NOT NULL DEFAULT 1,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ai_providers_active_priority` (`is_active`, `priority_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `otp_verifications` (
  `id` VARCHAR(36) NOT NULL,
  `target` VARCHAR(191) NOT NULL,
  `channel` ENUM('EMAIL', 'WHATSAPP') NOT NULL,
  `otp_hash` VARCHAR(255) NOT NULL,
  `purpose` ENUM('LOGIN', 'REGISTER', 'RESET_PASSWORD') NOT NULL DEFAULT 'LOGIN',
  `attempts` INT NOT NULL DEFAULT 0,
  `is_used` TINYINT(1) NOT NULL DEFAULT 0,
  `expires_at` TIMESTAMP NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_otp_target_channel` (`target`, `channel`, `is_used`, `expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `whatsapp_sessions` (
  `session_id` VARCHAR(191) NOT NULL,
  `data_key` VARCHAR(191) NOT NULL,
  `data_value` LONGTEXT NOT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`session_id`, `data_key`),
  KEY `idx_whatsapp_sessions_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `system_settings` (
  `key` VARCHAR(128) NOT NULL,
  `value` TEXT NOT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drivers` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `vehicle_type` ENUM('MOTOR', 'MOBIL') NOT NULL DEFAULT 'MOTOR',
  `vehicle_brand` VARCHAR(100) NOT NULL,
  `vehicle_plate` VARCHAR(32) NOT NULL,
  `ktp_number` VARCHAR(32) DEFAULT NULL,
  `sim_number` VARCHAR(32) DEFAULT NULL,
  `ktp_photo_url` VARCHAR(512) DEFAULT NULL,
  `sim_photo_url` VARCHAR(512) DEFAULT NULL,
  `stnk_photo_url` VARCHAR(512) DEFAULT NULL,
  `is_online` TINYINT(1) NOT NULL DEFAULT 0,
  `cash_float_amount` BIGINT NOT NULL DEFAULT 0,
  `last_lat` DECIMAL(10,7) DEFAULT NULL,
  `last_lng` DECIMAL(10,7) DEFAULT NULL,
  `rating_avg` DECIMAL(3,2) NOT NULL DEFAULT 5.00,
  `total_trips` INT NOT NULL DEFAULT 0,
  `approved_by` VARCHAR(36) DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_drivers_user_id` (`user_id`),
  UNIQUE KEY `uk_drivers_vehicle_plate` (`vehicle_plate`),
  KEY `idx_drivers_online_vehicle_cash` (`is_online`, `vehicle_type`, `cash_float_amount`),
  KEY `idx_drivers_approved_by` (`approved_by`),
  CONSTRAINT `fk_drivers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_drivers_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `stores` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `store_name` VARCHAR(191) NOT NULL,
  `category` VARCHAR(100) NOT NULL DEFAULT 'Kuliner',
  `description` TEXT DEFAULT NULL,
  `address` TEXT NOT NULL,
  `lat` DECIMAL(10,7) NOT NULL,
  `lng` DECIMAL(10,7) NOT NULL,
  `banner_url` VARCHAR(512) DEFAULT NULL,
  `logo_url` VARCHAR(512) DEFAULT NULL,
  `is_open` TINYINT(1) NOT NULL DEFAULT 1,
  `open_time` VARCHAR(16) NOT NULL DEFAULT '08:00',
  `close_time` VARCHAR(16) NOT NULL DEFAULT '22:00',
  `pin_hash` VARCHAR(255) DEFAULT NULL,
  `rating_avg` DECIMAL(3,2) NOT NULL DEFAULT 5.00,
  `approved_by` VARCHAR(36) DEFAULT NULL,
  `approved_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_stores_user_id` (`user_id`),
  KEY `idx_stores_is_open_category` (`is_open`, `category`),
  KEY `idx_stores_location` (`lat`, `lng`),
  KEY `idx_stores_approved_by` (`approved_by`),
  CONSTRAINT `fk_stores_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stores_approved_by` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `registrations` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `applicant_role` ENUM('DRIVER', 'STORE') NOT NULL,
  `status` ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
  `payload_json` JSON NOT NULL,
  `rejection_reason` TEXT DEFAULT NULL,
  `reviewed_by` VARCHAR(36) DEFAULT NULL,
  `reviewed_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_registrations_status_role` (`status`, `applicant_role`),
  KEY `idx_registrations_user_id` (`user_id`),
  KEY `idx_registrations_reviewed_by` (`reviewed_by`),
  CONSTRAINT `fk_registrations_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_registrations_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- MySQL unique indexes do not deduplicate NULL columns, so application handlers must
-- check existing (user_id, target_type, target_id) when store_id or menu_id is NULL.
CREATE TABLE IF NOT EXISTS `user_favorites` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `target_type` ENUM('STORE', 'MENU') NOT NULL,
  `store_id` VARCHAR(36) DEFAULT NULL,
  `menu_id` VARCHAR(36) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_favorites_entry` (`user_id`, `target_type`, `store_id`, `menu_id`),
  KEY `idx_user_favorites_store` (`store_id`),
  KEY `idx_user_favorites_menu` (`menu_id`),
  CONSTRAINT `fk_user_favorites_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- balance is SIGNED BIGINT because driver wallets can go negative down to -20000 for cash commission deductions.
CREATE TABLE IF NOT EXISTS `wallets` (
  `id` VARCHAR(36) NOT NULL,
  `owner_type` ENUM('DRIVER', 'STORE', 'CUSTOMER', 'PLATFORM') NOT NULL,
  `owner_id` VARCHAR(36) NOT NULL,
  `balance` BIGINT NOT NULL DEFAULT 0,
  `bank_name` VARCHAR(100) DEFAULT NULL,
  `bank_account_number` VARCHAR(64) DEFAULT NULL,
  `bank_account_holder` VARCHAR(191) DEFAULT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_wallets_owner` (`owner_type`, `owner_id`),
  KEY `idx_wallets_owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ai_chat_messages` (
  `id` VARCHAR(36) NOT NULL,
  `session_id` VARCHAR(64) NOT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `app_role` ENUM('CUSTOMER', 'DRIVER', 'STORE', 'ADMIN') NOT NULL,
  `sender` ENUM('USER', 'ASSISTANT', 'SYSTEM') NOT NULL,
  `message_text` TEXT NOT NULL,
  `provider_used` VARCHAR(191) DEFAULT NULL,
  `latency_ms` INT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ai_chat_session_created` (`session_id`, `created_at`),
  KEY `idx_ai_chat_user_id` (`user_id`),
  CONSTRAINT `fk_ai_chat_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `store_menus` (
  `id` VARCHAR(36) NOT NULL,
  `store_id` VARCHAR(36) NOT NULL,
  `name` VARCHAR(191) NOT NULL,
  `description` TEXT DEFAULT NULL,
  `category` VARCHAR(100) NOT NULL DEFAULT 'Makanan',
  `price` BIGINT NOT NULL,
  `photo_url` VARCHAR(512) DEFAULT NULL,
  `is_available` TINYINT(1) NOT NULL DEFAULT 1,
  `stock` INT NOT NULL DEFAULT 100,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_store_menus_store_available` (`store_id`, `is_available`),
  KEY `idx_store_menus_category` (`category`),
  CONSTRAINT `fk_store_menus_store` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `orders` (
  `id` VARCHAR(36) NOT NULL,
  `order_code` VARCHAR(32) NOT NULL,
  `service_type` ENUM('RIDE_MOTOR', 'RIDE_MOBIL', 'FLEX_FOOD', 'FLEX_SEND') NOT NULL,
  `customer_id` VARCHAR(36) NOT NULL,
  `driver_id` VARCHAR(36) DEFAULT NULL,
  `store_id` VARCHAR(36) DEFAULT NULL,
  `vehicle_type` ENUM('MOTOR', 'MOBIL') NOT NULL DEFAULT 'MOTOR',
  `status` ENUM(
    'CREATED',
    'WAITING_STORE_CONFIRM',
    'STORE_PREPARING',
    'SEARCHING_DRIVER',
    'DRIVER_ASSIGNED',
    'DRIVER_AT_PICKUP',
    'IN_TRANSIT',
    'DELIVERED',
    'COMPLETED',
    'CANCELLED',
    'TALANGAN_CLAIMED'
  ) NOT NULL DEFAULT 'CREATED',
  `payment_method` ENUM('CASH', 'QRIS') NOT NULL DEFAULT 'CASH',
  `payment_status` ENUM('UNPAID', 'PENDING', 'PAID', 'REFUNDED') NOT NULL DEFAULT 'UNPAID',
  `pickup_address` TEXT NOT NULL,
  `pickup_lat` DECIMAL(10,7) NOT NULL,
  `pickup_lng` DECIMAL(10,7) NOT NULL,
  `dropoff_address` TEXT NOT NULL,
  `dropoff_lat` DECIMAL(10,7) NOT NULL,
  `dropoff_lng` DECIMAL(10,7) NOT NULL,
  `distance_km` DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `duration_min` INT NOT NULL DEFAULT 0,
  `delivery_fee` BIGINT NOT NULL DEFAULT 0,
  `items_subtotal` BIGINT NOT NULL DEFAULT 0,
  `talangan_est_amount` BIGINT NOT NULL DEFAULT 0,
  `talangan_actual_amount` BIGINT NOT NULL DEFAULT 0,
  `parking_fee` BIGINT NOT NULL DEFAULT 0,
  `discount_amount` BIGINT NOT NULL DEFAULT 0,
  `platform_commission_driver` BIGINT NOT NULL DEFAULT 0,
  `platform_commission_store` BIGINT NOT NULL DEFAULT 0,
  `total_customer_pay` BIGINT NOT NULL DEFAULT 0,
  `receipt_photo_url` VARCHAR(512) DEFAULT NULL,
  `parking_photo_url` VARCHAR(512) DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  `promo_code` VARCHAR(64) DEFAULT NULL,
  `cancel_reason` TEXT DEFAULT NULL,
  `offer_expires_at` TIMESTAMP NULL DEFAULT NULL,
  `accepted_at` TIMESTAMP NULL DEFAULT NULL,
  `completed_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_orders_order_code` (`order_code`),
  KEY `idx_orders_status_service` (`status`, `service_type`),
  KEY `idx_orders_customer_created` (`customer_id`, `created_at`),
  KEY `idx_orders_driver_status` (`driver_id`, `status`),
  KEY `idx_orders_store_status` (`store_id`, `status`),
  CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_orders_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_orders_store` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `withdrawals` (
  `id` VARCHAR(36) NOT NULL,
  `wallet_id` VARCHAR(36) NOT NULL,
  `requester_user_id` VARCHAR(36) NOT NULL,
  `amount` BIGINT NOT NULL,
  `admin_fee` BIGINT NOT NULL DEFAULT 0,
  `net_amount` BIGINT NOT NULL,
  `bank_name` VARCHAR(100) NOT NULL,
  `bank_account_number` VARCHAR(64) NOT NULL,
  `bank_account_holder` VARCHAR(191) NOT NULL,
  `status` ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'PENDING',
  `transfer_proof_url` VARCHAR(512) DEFAULT NULL,
  `admin_notes` TEXT DEFAULT NULL,
  `processed_by` VARCHAR(36) DEFAULT NULL,
  `processed_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_withdrawals_status_created` (`status`, `created_at`),
  KEY `idx_withdrawals_wallet_id` (`wallet_id`),
  KEY `idx_withdrawals_requester` (`requester_user_id`),
  KEY `idx_withdrawals_processed_by` (`processed_by`),
  CONSTRAINT `fk_withdrawals_wallet` FOREIGN KEY (`wallet_id`) REFERENCES `wallets` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_withdrawals_requester` FOREIGN KEY (`requester_user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_withdrawals_processed_by` FOREIGN KEY (`processed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `order_items` (
  `id` VARCHAR(36) NOT NULL,
  `order_id` VARCHAR(36) NOT NULL,
  `menu_id` VARCHAR(36) DEFAULT NULL,
  `item_name` VARCHAR(191) NOT NULL,
  `unit_price` BIGINT NOT NULL DEFAULT 0,
  `qty` INT NOT NULL DEFAULT 1,
  `subtotal` BIGINT NOT NULL DEFAULT 0,
  `notes` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_order_items_order_id` (`order_id`),
  KEY `idx_order_items_menu_id` (`menu_id`),
  CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_order_items_menu` FOREIGN KEY (`menu_id`) REFERENCES `store_menus` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ratings` (
  `id` VARCHAR(36) NOT NULL,
  `order_id` VARCHAR(36) NOT NULL,
  `customer_id` VARCHAR(36) NOT NULL,
  `driver_id` VARCHAR(36) DEFAULT NULL,
  `store_id` VARCHAR(36) DEFAULT NULL,
  `driver_Score` TINYINT DEFAULT NULL,
  `store_score` TINYINT DEFAULT NULL,
  `comment` TEXT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ratings_order_id` (`order_id`),
  KEY `idx_ratings_customer_id` (`customer_id`),
  KEY `idx_ratings_driver_id` (`driver_id`),
  KEY `idx_ratings_store_id` (`store_id`),
  CONSTRAINT `fk_ratings_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ratings_customer` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ratings_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_ratings_store` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `qris_transactions` (
  `id` VARCHAR(36) NOT NULL,
  `reference_id` VARCHAR(64) NOT NULL,
  `purpose` ENUM('ORDER_PAYMENT', 'DRIVER_TOPUP') NOT NULL,
  `order_id` VARCHAR(36) DEFAULT NULL,
  `user_id` VARCHAR(36) NOT NULL,
  `base_amount` BIGINT DEFAULT NULL,
  `unique_code` INT DEFAULT NULL,
  `amount` BIGINT NOT NULL,
  `qris_payload` TEXT NOT NULL,
  `status` ENUM('PENDING', 'PAID', 'EXPIRED', 'FAILED') NOT NULL DEFAULT 'PENDING',
  `expires_at` TIMESTAMP NOT NULL,
  `paid_at` TIMESTAMP NULL DEFAULT NULL,
  `verified_by` VARCHAR(36) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_qris_reference_id` (`reference_id`),
  KEY `idx_qris_status_expires` (`status`, `expires_at`),
  KEY `idx_qris_order_id` (`order_id`),
  KEY `idx_qris_user_id` (`user_id`),
  CONSTRAINT `fk_qris_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_qris_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- amount, balance_before, and balance_after are SIGNED BIGINT for negative driver balance tracking.
CREATE TABLE IF NOT EXISTS `wallet_transactions` (
  `id` VARCHAR(36) NOT NULL,
  `wallet_id` VARCHAR(36) NOT NULL,
  `tx_type` ENUM(
    'TOPUP_QRIS',
    'ORDER_EARNING',
    'COMMISSION_DEDUCT',
    'WITHDRAWAL',
    'TALANGAN_REIMBURSE',
    'MANUAL_ADJUST'
  ) NOT NULL,
  `amount` BIGINT NOT NULL,
  `balance_before` BIGINT NOT NULL,
  `balance_after` BIGINT NOT NULL,
  `reference_type` VARCHAR(64) DEFAULT NULL,
  `reference_id` VARCHAR(64) DEFAULT NULL,
  `description` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_wallet_tx_wallet_created` (`wallet_id`, `created_at`),
  KEY `idx_wallet_tx_reference` (`reference_type`, `reference_id`),
  CONSTRAINT `fk_wallet_tx_wallet` FOREIGN KEY (`wallet_id`) REFERENCES `wallets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `talangan_claims` (
  `id` VARCHAR(36) NOT NULL,
  `order_id` VARCHAR(36) NOT NULL,
  `driver_id` VARCHAR(36) NOT NULL,
  `claimed_amount` BIGINT NOT NULL,
  `goods_photo_url` VARCHAR(512) NOT NULL,
  `receipt_photo_url` VARCHAR(512) NOT NULL,
  `status` ENUM('SUBMITTED_STEP1', 'APPROVED_FOR_DONATION', 'COMPLETED_REIMBURSED', 'REJECTED') NOT NULL DEFAULT 'SUBMITTED_STEP1',
  `orphanage_name` VARCHAR(191) DEFAULT NULL,
  `donation_photo_url` VARCHAR(512) DEFAULT NULL,
  `admin_notes` TEXT DEFAULT NULL,
  `reviewed_by` VARCHAR(36) DEFAULT NULL,
  `step1_approved_at` TIMESTAMP NULL DEFAULT NULL,
  `reimbursed_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_talangan_claims_order_id` (`order_id`),
  KEY `idx_talangan_claims_status` (`status`),
  KEY `idx_talangan_claims_driver_id` (`driver_id`),
  KEY `idx_talangan_claims_reviewed_by` (`reviewed_by`),
  CONSTRAINT `fk_talangan_claims_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_talangan_claims_driver` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `fk_talangan_claims_reviewed_by` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `support_tickets` (
  `id` VARCHAR(36) NOT NULL,
  `user_id` VARCHAR(36) DEFAULT NULL,
  `order_id` VARCHAR(36) DEFAULT NULL,
  `channel` ENUM('IN_APP', 'EMAIL', 'WHATSAPP') NOT NULL DEFAULT 'IN_APP',
  `sender_contact` VARCHAR(191) NOT NULL,
  `subject` VARCHAR(255) NOT NULL,
  `body` TEXT NOT NULL,
  `status` ENUM('OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED') NOT NULL DEFAULT 'OPEN',
  `admin_reply` TEXT DEFAULT NULL,
  `replied_by` VARCHAR(36) DEFAULT NULL,
  `replied_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_support_tickets_status_created` (`status`, `created_at`),
  KEY `idx_support_tickets_user_id` (`user_id`),
  KEY `idx_support_tickets_order_id` (`order_id`),
  KEY `idx_support_tickets_replied_by` (`replied_by`),
  CONSTRAINT `fk_support_tickets_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_support_tickets_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_support_tickets_replied_by` FOREIGN KEY (`replied_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
