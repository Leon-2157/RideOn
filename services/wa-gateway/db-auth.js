const fs = require('fs');
const path = require('path');
let mysql = null;
try {
    mysql = require('mysql2/promise');
} catch (_) {
    // Falls back to local filesystem storage if mysql2 is unavailable.
}
const { initAuthCreds, BufferJSON, proto } = require('@whiskeysockets/baileys');

let cachedPool = null;

function getDbPool() {
    if (cachedPool) return cachedPool;
    if (!mysql) return null;

    const dbHost = process.env.DB_HOST;
    const dbUser = process.env.DB_USERNAME || process.env.DB_USER;
    const dbPassword = process.env.DB_PASSWORD || '';
    const dbName = process.env.DB_DATABASE || process.env.DB_NAME;
    const dbPort = parseInt(process.env.DB_PORT || '3306', 10);

    if (dbHost && dbUser && dbName) {
        try {
            cachedPool = mysql.createPool({
                host: dbHost,
                port: dbPort,
                user: dbUser,
                password: dbPassword,
                database: dbName,
                waitForConnections: true,
                connectionLimit: 2,
                maxIdle: 2,
                idleTimeout: 30000,
                queueLimit: 0,
                enableKeepAlive: true,
                keepAliveInitialDelay: 10000,
                ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : undefined
            });
            return cachedPool;
        } catch (err) {
            console.error('[DB-AUTH] Failed to initialize MySQL pool:', err.message);
            cachedPool = null;
            return null;
        }
    }
    return null;
}

async function createAuthState(options = {}) {
    const pool = getDbPool();
    const sessionId = options.sessionId || process.env.WHATSAPP_SESSION_ID || 'default';

    if (pool) {
        try {
            await pool.query(`
                CREATE TABLE IF NOT EXISTS whatsapp_sessions (
                    \`session_id\` VARCHAR(191) NOT NULL,
                    \`data_key\` VARCHAR(191) NOT NULL,
                    \`data_value\` LONGTEXT NOT NULL,
                    \`updated_at\` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                    PRIMARY KEY (\`session_id\`, \`data_key\`),
                    KEY \`idx_whatsapp_sessions_id\` (\`session_id\`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            `);

            console.log(`[DB-AUTH] Connected to MySQL whatsapp_sessions table (session_id=${sessionId}).`);

            const [rows] = await pool.query(
                'SELECT `data_value` FROM whatsapp_sessions WHERE `session_id` = ? AND `data_key` = ?',
                [sessionId, 'creds']
            );
            let creds;
            if (rows.length > 0 && rows[0].data_value) {
                try {
                    creds = JSON.parse(rows[0].data_value, BufferJSON.reviver);
                } catch (e) {
                    console.error('[DB-AUTH] Failed to parse existing creds, initializing fresh:', e.message);
                    creds = initAuthCreds();
                }
            } else {
                creds = initAuthCreds();
            }

            return {
                state: {
                    creds,
                    keys: {
                        get: async (type, ids) => {
                            const data = {};
                            if (!ids || ids.length === 0) return data;

                            const keyNames = ids.map(id => `${type}-${id}`);
                            try {
                                const [keyRows] = await pool.query(
                                    'SELECT `data_key`, `data_value` FROM whatsapp_sessions WHERE `session_id` = ? AND `data_key` IN (?)',
                                    [sessionId, keyNames]
                                );
                                for (const row of keyRows) {
                                    const rawId = row.data_key.substring(type.length + 1);
                                    if (row.data_value) {
                                        try {
                                            let val = JSON.parse(row.data_value, BufferJSON.reviver);
                                            if (type === 'app-state-sync-key' && val) {
                                                val = proto.Message.AppStateSyncKeyData.fromObject(val);
                                            }
                                            data[rawId] = val;
                                        } catch (pe) {
                                            console.error(`[DB-AUTH] Parse error for ${row.data_key}:`, pe.message);
                                        }
                                    }
                                }
                            } catch (err) {
                                console.error(`[DB-AUTH] Error fetching keys (${type}):`, err.message);
                            }
                            return data;
                        },
                        set: async (data) => {
                            const tasks = [];
                            for (const category of Object.keys(data)) {
                                for (const id of Object.keys(data[category])) {
                                    const value = data[category][id];
                                    const keyName = `${category}-${id}`;
                                    if (value) {
                                        const serialized = JSON.stringify(value, BufferJSON.replacer);
                                        tasks.push(
                                            pool.query(
                                                'INSERT INTO whatsapp_sessions (`session_id`, `data_key`, `data_value`, `updated_at`) VALUES (?, ?, ?, NOW()) ON DUPLICATE KEY UPDATE `data_value` = VALUES(`data_value`), `updated_at` = NOW()',
                                                [sessionId, keyName, serialized]
                                            ).catch(err => console.error(`[DB-AUTH] Error saving key ${keyName}:`, err.message))
                                        );
                                    } else {
                                        tasks.push(
                                            pool.query(
                                                'DELETE FROM whatsapp_sessions WHERE `session_id` = ? AND `data_key` = ?',
                                                [sessionId, keyName]
                                            ).catch(err => console.error(`[DB-AUTH] Error deleting key ${keyName}:`, err.message))
                                        );
                                    }
                                }
                            }
                            await Promise.all(tasks);
                        }
                    }
                },
                saveCreds: async () => {
                    try {
                        const serialized = JSON.stringify(creds, BufferJSON.replacer);
                        await pool.query(
                            'INSERT INTO whatsapp_sessions (`session_id`, `data_key`, `data_value`, `updated_at`) VALUES (?, \'creds\', ?, NOW()) ON DUPLICATE KEY UPDATE `data_value` = VALUES(`data_value`), `updated_at` = NOW()',
                            [sessionId, serialized]
                        );
                    } catch (err) {
                        console.error('[DB-AUTH] Error saving creds:', err.message);
                    }
                },
                clearChatSessions: async () => {
                    try {
                        await pool.query(
                            "DELETE FROM whatsapp_sessions WHERE `session_id` = ? AND (`data_key` LIKE 'session-%' OR `data_key` LIKE 'sender-key-%')",
                            [sessionId]
                        );
                        console.log('[DB-AUTH] Cleared session and sender-key ratchets from database.');
                    } catch (err) {
                        console.error('[DB-AUTH] Error clearing chat sessions:', err.message);
                    }
                },
                clearAuth: async () => {
                    try {
                        await pool.query('DELETE FROM whatsapp_sessions WHERE `session_id` = ?', [sessionId]);
                        console.log('[DB-AUTH] Cleared all auth credentials from database.');
                    } catch (err) {
                        console.error('[DB-AUTH] Error clearing auth:', err.message);
                    }
                }
            };
        } catch (dbErr) {
            console.warn('[DB-AUTH] MySQL connection failed, falling back to filesystem storage:', dbErr.message);
        }
    }

    const sessionDir = path.resolve(options.sessionDir || process.env.SESSION_DIR || path.join(__dirname, 'storage/sessions'));
    if (!fs.existsSync(sessionDir)) {
        fs.mkdirSync(sessionDir, { recursive: true });
    }

    console.log('[FILE-AUTH] Using filesystem storage at:', sessionDir);

    const { useMultiFileAuthState } = require('@whiskeysockets/baileys');
    const authState = await useMultiFileAuthState(sessionDir);

    return {
        ...authState,
        clearAuth: async () => {
            try {
                if (fs.existsSync(sessionDir)) {
                    fs.rmSync(sessionDir, { recursive: true, force: true });
                    fs.mkdirSync(sessionDir, { recursive: true });
                }
                console.log('[FILE-AUTH] Cleared filesystem session files.');
            } catch (err) {
                console.error('[FILE-AUTH] Error clearing auth files:', err.message);
            }
        }
    };
}

module.exports = { createAuthState, getDbPool };
