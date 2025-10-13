'use strict';

// Parse command line arguments
const args = process.argv.slice(2);
const config = {};

// Parse arguments in format: --key=value or --key value
for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg.startsWith('--')) {
        const [key, value] = arg.includes('=') 
            ? arg.substring(2).split('=', 2)
            : [arg.substring(2), args[i + 1] && !args[i + 1].startsWith('--') ? args[++i] : true];
        
        // Convert string values to appropriate types
        if (value === 'true') config[key] = true;
        else if (value === 'false') config[key] = false;
        else if (!isNaN(value) && value !== '') config[key] = Number(value);
        else config[key] = value;
    }
}

// Default configuration
const defaultConfig = {
    local: false,
    debug: true,
    container: {
        ipAddress: '172.20.0.2',
        name: 'CT101',
        mountPath: {
            prefix: '/var/snap/lxd/common/mntns/var/snap/lxd/common/lxd/storage-pools/default/containers/',
            suffix: 'rootfs'
        }
    },
    logging: {
        streamOutput: '/root/MITM_data/sessions',
        loginAttempts: '/root/MITM_data/login_attempts',
        logins: '/root/MITM_data/logins'
    },
    server: {
        maxAttemptsPerConnection: 6,
        listenIP: '0.0.0.0',
        listenPort: 10000,
        identifier: 'SSH-2.0-OpenSSH_6.6.1p1 Ubuntu-2ubuntu2',
        bannerFile: ''
    },
    autoAccess: {
        enabled: true,
        cacheSize: 5000,
        barrier: {
            normalDist: {
                enabled: false,
                mean: 6,
                standardDeviation: 1,
            },
            fixed: {
                enabled: true,
                upperLimit: true,
                attempts: 3,
            },
        }
    }
};

// Merge command line config with defaults
function mergeConfig(defaults, overrides) {
    const result = JSON.parse(JSON.stringify(defaults));
    
    for (const key in overrides) {
        if (typeof overrides[key] === 'object' && overrides[key] !== null && !Array.isArray(overrides[key])) {
            result[key] = mergeConfig(result[key] || {}, overrides[key]);
        } else {
            result[key] = overrides[key];
        }
    }
    
    return result;
}

module.exports = mergeConfig(defaultConfig, config);
