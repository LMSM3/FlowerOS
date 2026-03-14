// ═══════════════════════════════════════════════════════════════════════════
//  FlowerOS User Database - Secure XML Backend
//  Using "seeding" for hash initialization (plant terminology)
// ═══════════════════════════════════════════════════════════════════════════

#ifndef FLOWER_USERDB_H
#define FLOWER_USERDB_H

#include <stdint.h>
#include <stdbool.h>
#include <time.h>

// ═══════════════════════════════════════════════════════════════════════════
//  User Database Constants
// ═══════════════════════════════════════════════════════════════════════════

#define FLOWER_USER_MAX_NAME 64
#define FLOWER_USER_MAX_EMAIL 128
#define FLOWER_USER_MAX_HASH 128
#define FLOWER_USER_MAX_SALT 64

// User roles (plant hierarchy)
#define FLOWER_ROLE_SEED      0  // New user (seed)
#define FLOWER_ROLE_SPROUT    1  // Basic user (sprout)
#define FLOWER_ROLE_STEM      2  // Standard user (stem)
#define FLOWER_ROLE_BLOOM     3  // Power user (bloom)
#define FLOWER_ROLE_GARDENER  4  // Administrator (gardener)
#define FLOWER_ROLE_ROOT      5  // System administrator (root)

// Permission flags (botanical)
#define FLOWER_PERM_SPROUT    0x0001  // Read access
#define FLOWER_PERM_GROW      0x0002  // Write access
#define FLOWER_PERM_BLOOM     0x0004  // Execute access
#define FLOWER_PERM_POLLINATE 0x0008  // Network access
#define FLOWER_PERM_GARDEN    0x0010  // Memory management
#define FLOWER_PERM_PETAL     0x0020  // GPU access
#define FLOWER_PERM_ROOT      0x8000  // Root access

// ═══════════════════════════════════════════════════════════════════════════
//  User Structure
// ═══════════════════════════════════════════════════════════════════════════

typedef struct {
    uint64_t user_id;                          // Unique ID
    char username[FLOWER_USER_MAX_NAME];       // Username
    char email[FLOWER_USER_MAX_EMAIL];         // Email
    
    // Security (seeded hash)
    char password_hash[FLOWER_USER_MAX_HASH];  // SHA-256 hash
    char salt[FLOWER_USER_MAX_SALT];           // "Salt" - random seed for hash
    uint32_t hash_seed;                        // "Seeding" value for hash
    const char* hash_algorithm;                // "SHA-256", "bcrypt", etc.
    
    // Permissions (botanical)
    uint8_t role;                              // Role level
    uint16_t permissions;                      // Permission flags
    
    // Metadata
    time_t created_at;                         // "Germination" time
    time_t last_login;                         // "Last bloom" time
    uint64_t login_count;                      // "Bloom count"
    bool account_active;                       // "Blooming" status
    
    // Garden allocation (user quota)
    uint64_t garden_quota_bytes;               // Memory quota
    uint64_t garden_used_bytes;                // Memory used
    
    // GPU allocation (petal quota)
    uint32_t petal_quota;                      // GPU core quota
    uint32_t petals_used;                      // GPU cores used
    
} flower_user_t;

// ═══════════════════════════════════════════════════════════════════════════
//  User Database Structure
// ═══════════════════════════════════════════════════════════════════════════

typedef struct {
    flower_user_t* users;          // Array of users
    uint32_t user_count;           // Number of users
    uint32_t user_capacity;        // Capacity
    
    const char* xml_path;          // XML database path
    bool xml_loaded;               // Database loaded
    
    // Security seeds
    uint32_t master_seed;          // "Master seed" for database
    uint32_t session_seed;         // "Session seed" for current session
    
    // Statistics
    uint64_t total_blooms;         // Total logins
    uint64_t active_blooms;        // Active sessions
    
} flower_userdb_t;

// ═══════════════════════════════════════════════════════════════════════════
//  User Database API
// ═══════════════════════════════════════════════════════════════════════════

// Initialization
int flower_userdb_init(flower_userdb_t* db, const char* xml_path);
int flower_userdb_seed(flower_userdb_t* db, uint32_t master_seed);
int flower_userdb_load_xml(flower_userdb_t* db);
int flower_userdb_save_xml(flower_userdb_t* db);
void flower_userdb_cleanup(flower_userdb_t* db);

// User management (botanical operations)
int flower_user_germinate(flower_userdb_t* db, const char* username, const char* email, 
                          const char* password);  // Create user ("germinate seed")
int flower_user_bloom(flower_userdb_t* db, const char* username, const char* password);  
                                                  // Login ("bloom")
int flower_user_wilt(flower_userdb_t* db, uint64_t user_id);  
                                                  // Logout ("wilt")
int flower_user_uproot(flower_userdb_t* db, uint64_t user_id);  
                                                  // Delete user ("uproot")

// User queries
flower_user_t* flower_user_find_by_id(flower_userdb_t* db, uint64_t user_id);
flower_user_t* flower_user_find_by_name(flower_userdb_t* db, const char* username);

// Permission management (growth)
int flower_user_grant_permission(flower_userdb_t* db, uint64_t user_id, uint16_t perm);
int flower_user_revoke_permission(flower_userdb_t* db, uint64_t user_id, uint16_t perm);
bool flower_user_has_permission(flower_user_t* user, uint16_t perm);

// Role management (maturity)
int flower_user_set_role(flower_userdb_t* db, uint64_t user_id, uint8_t role);
const char* flower_user_role_name(uint8_t role);

// Resource management (garden/petal allocation)
int flower_user_allocate_garden(flower_userdb_t* db, uint64_t user_id, uint64_t bytes);
int flower_user_allocate_petals(flower_userdb_t* db, uint64_t user_id, uint32_t count);
int flower_user_free_garden(flower_userdb_t* db, uint64_t user_id, uint64_t bytes);
int flower_user_free_petals(flower_userdb_t* db, uint64_t user_id, uint32_t count);

// Security (seeding & hashing)
int flower_user_hash_password(const char* password, const char* salt, uint32_t seed, 
                               char* hash_out);
int flower_user_generate_salt(char* salt_out, uint32_t seed);
bool flower_user_verify_password(flower_user_t* user, const char* password);

// Display
void flower_userdb_print_status(flower_userdb_t* db);
void flower_user_print_info(flower_user_t* user);

// ═══════════════════════════════════════════════════════════════════════════
//  XML Format (Example)
// ═══════════════════════════════════════════════════════════════════════════
/*
<?xml version="1.0" encoding="UTF-8"?>
<flower_garden database_version="1.3.0">
  <master_seed value="0x1A2B3C4D" />
  <statistics>
    <total_blooms count="12847" />
    <active_blooms count="42" />
  </statistics>
  
  <users>
    <seed user_id="1" role="ROOT">
      <identity>
        <username>root</username>
        <email>root@floweros.local</email>
      </identity>
      <security>
        <password_hash algorithm="SHA-256">a1b2c3d4e5f6...</password_hash>
        <salt>random_salt_value</salt>
        <hash_seed value="0x9F8E7D6C" />
      </security>
      <permissions flags="0x803F" />
      <timeline>
        <germinated timestamp="1700000000" />
        <last_bloom timestamp="1700123456" />
        <bloom_count>247</bloom_count>
      </timeline>
      <resources>
        <garden quota="1099511627776" used="214748364800" />
        <petals quota="27648" used="6912" />
      </resources>
      <status active="true" />
    </seed>
    
    <seed user_id="2" role="GARDENER">
      <identity>
        <username>admin</username>
        <email>admin@floweros.local</email>
      </identity>
      <!-- ... -->
    </seed>
  </users>
</flower_garden>
*/

#endif // FLOWER_USERDB_H
