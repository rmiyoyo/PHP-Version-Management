<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Version Management</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            line-height: 1.6;
            background: linear-gradient(135deg, #1a4a3a 0%, #2d5a4a 50%, #3a6b5a 100%);
            color: #e8f5e8;
            min-height: 100vh;
            padding: 0;
        }

        .container {
            max-width: 1000px;
            margin: 0 auto;
            padding: 2rem;
        }

        .header {
            text-align: center;
            margin-bottom: 3rem;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 15px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .header h1 {
            font-size: 3rem;
            color: #90ee90;
            text-shadow: 0 2px 10px rgba(144, 238, 144, 0.3);
            margin-bottom: 0.5rem;
            font-weight: 700;
        }

        .header p {
            font-size: 1.2rem;
            color: #c8e6c9;
            opacity: 0.9;
        }

        .section {
            background: rgba(255, 255, 255, 0.08);
            margin: 2rem 0;
            padding: 2rem;
            border-radius: 12px;
            border-left: 4px solid #4caf50;
            backdrop-filter: blur(5px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }

        .section h2 {
            color: #90ee90;
            font-size: 1.8rem;
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .section h3 {
            color: #a5d6a7;
            font-size: 1.3rem;
            margin: 1.5rem 0 0.8rem 0;
        }

        .code-block {
            background: rgba(0, 0, 0, 0.4);
            border: 1px solid #4caf50;
            border-radius: 8px;
            padding: 1.5rem;
            margin: 1rem 0;
            font-family: 'Fira Code', 'Monaco', monospace;
            font-size: 0.9rem;
            overflow-x: auto;
            position: relative;
        }

        .code-block::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 3px;
            background: linear-gradient(90deg, #4caf50, #8bc34a, #4caf50);
            border-radius: 8px 8px 0 0;
        }

        .error-code {
            color: #ffcdd2;
            background: rgba(244, 67, 54, 0.1);
            border-color: #f44336;
        }

        .success-code {
            color: #c8e6c9;
            background: rgba(76, 175, 80, 0.1);
            border-color: #4caf50;
        }

        .steps {
            background: rgba(76, 175, 80, 0.1);
            border-radius: 10px;
            padding: 1.5rem;
            margin: 1rem 0;
        }

        .steps ol {
            padding-left: 1.5rem;
        }

        .steps li {
            margin: 0.8rem 0;
            color: #e8f5e8;
            position: relative;
        }

        .steps li::marker {
            color: #90ee90;
            font-weight: bold;
        }

        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 1.5rem;
            margin: 1.5rem 0;
        }

        .feature-card {
            background: rgba(76, 175, 80, 0.1);
            padding: 1.5rem;
            border-radius: 10px;
            border: 1px solid rgba(76, 175, 80, 0.3);
        }

        .feature-card h4 {
            color: #90ee90;
            margin-bottom: 0.8rem;
            font-size: 1.1rem;
        }

        .feature-card ul {
            list-style: none;
            padding-left: 0;
        }

        .feature-card li {
            padding: 0.3rem 0;
            position: relative;
            padding-left: 1.5rem;
        }

        .feature-card li::before {
            content: '✓';
            position: absolute;
            left: 0;
            color: #4caf50;
            font-weight: bold;
        }

        .options-list {
            background: rgba(76, 175, 80, 0.05);
            border-radius: 8px;
            padding: 1rem;
            margin: 1rem 0;
        }

        .options-list ol {
            padding-left: 1.5rem;
        }

        .options-list li {
            padding: 0.5rem 0;
            color: #c8e6c9;
        }

        .highlight {
            background: rgba(144, 238, 144, 0.2);
            padding: 0.2rem 0.5rem;
            border-radius: 4px;
            color: #90ee90;
            font-weight: bold;
        }

        .icon {
            width: 24px;
            height: 24px;
            fill: currentColor;
        }

        @media (max-width: 768px) {
            .container {
                padding: 1rem;
            }
            
            .header h1 {
                font-size: 2rem;
            }
            
            .feature-grid {
                grid-template-columns: 1fr;
            }
        }

        /* Scrollbar styling */
        ::-webkit-scrollbar {
            width: 8px;
        }

        ::-webkit-scrollbar-track {
            background: rgba(255, 255, 255, 0.1);
        }

        ::-webkit-scrollbar-thumb {
            background: #4caf50;
            border-radius: 4px;
        }

        ::-webkit-scrollbar-thumb:hover {
            background: #66bb6a;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>
                <svg class="icon" viewBox="0 0 24 24" style="width: 48px; height: 48px; margin-right: 1rem;">
                    <path d="M12,2A10,10 0 0,0 2,12A10,10 0 0,0 12,22A10,10 0 0,0 22,12A10,10 0 0,0 12,2M11,16.5L6.5,12L8.5,10L11,12.5L15.5,8L17.5,10L11,16.5Z"/>
                </svg>
                PHP Version Management
            </h1>
            <p>A bash script that automates PHP and Node.js version configuration for shared hosting environments.</p>
        </div>

        <div class="section">
            <h2>
                <svg class="icon" viewBox="0 0 24 24">
                    <path d="M13,14H11V10H13M13,18H11V16H13M1,21H23L12,2L1,21Z"/>
                </svg>
                Common Errors This Script Fixes
            </h2>
            
            <h3>PHP/Composer Errors:</h3>
            <div class="code-block error-code">
Composer detected issues in your platform: Your Composer dependencies require a PHP version ">= 8.0.2". You are running 7.4.32.
            </div>
            
            <div class="code-block error-code">
Fatal error: Composer detected issues in your platform: Your Composer dependencies require a PHP version ">= 8.1.0"
            </div>

            <h3>Node.js/NPM Errors:</h3>
            <div class="code-block error-code">
npm WARN EBADENGINE Unsupported engine { package: 'vite@6.2.5', required: { node: '^18.0.0 || ^20.0.0 || >=22.0.0' }, current: { node: 'v16.20.2' } }
            </div>
            
            <div class="code-block error-code">
sh: line 1: /home/user/project/node_modules/.bin/vite: Permission denied
            </div>
            
            <div class="code-block error-code">
npm ERR! engine Unsupported engine for laravel-vite-plugin@1.2.0: wanted: {"node":"^18.0.0 || ^20.0.0 || >=22.0.0"} (current: {"node":"16.20.2"})
            </div>
        </div>

        <div class="section">
            <h2>
                <svg class="icon" viewBox="0 0 24 24">
                    <path d="M8.5,13.5L11,16.5L16.5,11L15,9.5L11,13.5L10,12.5L8.5,13.5M12,2A10,10 0 0,1 22,12A10,10 0 0,1 12,22A10,10 0 0,1 2,12A10,10 0 0,1 12,2M12,4A8,8 0 0,0 4,12A8,8 0 0,0 12,20A8,8 0 0,0 20,12A8,8 0 0,0 12,4Z"/>
                </svg>
                Quick Start
            </h2>
            
            <div class="steps">
                <ol>
                    <li>Upload <span class="highlight">server-env-setup.sh</span> to your server's home directory</li>
                    <li>Make it executable: <code class="highlight">chmod +x server-env-setup.sh</code></li>
                    <li>Run the script: <code class="highlight">./server-env-setup.sh</code></li>
                </ol>
            </div>
        </div>

        <div class="section">
            <h2>
                <svg class="icon" viewBox="0 0 24 24">
                    <path d="M9,22A1,1 0 0,1 8,21V18H4A2,2 0 0,1 2,16V4C2,2.89 2.9,2 4,2H20A2,2 0 0,1 22,4V16A2,2 0 0,1 20,18H13.9L10.2,21.71C10,21.9 9.75,22 9.5,22V22H9Z"/>
                </svg>
                What It Does
            </h2>
            
            <div class="feature-grid">
                <div class="feature-card">
                    <h4>PHP Configuration:</h4>
                    <ul>
                        <li>Creates symlinks to specify PHP versions for CLI usage</li>
                        <li>Configures aliases as fallback method</li>
                        <li>Supports PHP versions 5.6 through 8.3</li>
                        <li>Automatically sets up Composer to use the correct PHP version</li>
                    </ul>
                </div>
                
                <div class="feature-card">
                    <h4>Node.js Installation:</h4>
                    <ul>
                        <li>Installs Node Version Manager (NVM) if not present</li>
                        <li>Downloads and configures specified Node.js version (18, 20, or 22)</li>
                        <li>Sets the chosen version as default</li>
                        <li>Updates shell configuration automatically</li>
                    </ul>
                </div>
                
                <div class="feature-card">
                    <h4>Permission Fixes:</h4>
                    <ul>
                        <li>Resolves common <code>node_modules/.bin</code> permission issues</li>
                        <li>Configures npm cache permissions</li>
                        <li>Fixes executable permissions for build tools</li>
                    </ul>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>
                <svg class="icon" viewBox="0 0 24 24">
                    <path d="M12,15.5A3.5,3.5 0 0,1 8.5,12A3.5,3.5 0 0,1 12,8.5A3.5,3.5 0 0,1 15.5,12A3.5,3.5 0 0,1 12,15.5M19.43,12.97C19.47,12.65 19.5,12.33 19.5,12C19.5,11.67 19.47,11.34 19.43,11L21.54,9.37C21.73,9.22 21.78,8.95 21.66,8.73L19.66,5.27C19.54,5.05 19.27,4.96 19.05,5.05L16.56,6.05C16.04,5.66 15.5,5.32 14.87,5.07L14.5,2.42C14.46,2.18 14.25,2 14,2H10C9.75,2 9.54,2.18 9.5,2.42L9.13,5.07C8.5,5.32 7.96,5.66 7.44,6.05L4.95,5.05C4.73,4.96 4.46,5.05 4.34,5.27L2.34,8.73C2.22,8.95 2.27,9.22 2.46,9.37L4.57,11C4.53,11.34 4.5,11.67 4.5,12C4.5,12.33 4.53,12.65 4.57,12.97L2.46,14.63C2.27,14.78 2.22,15.05 2.34,15.27L4.34,18.73C4.46,18.95 4.73,19.03 4.95,18.95L7.44,17.94C7.96,18.34 8.5,18.68 9.13,18.93L9.5,21.58C9.54,21.82 9.75,22 10,22H14C14.25,22 14.46,21.82 14.5,21.58L14.87,18.93C15.5,18.68 16.04,18.34 16.56,17.94L19.05,18.95C19.27,19.03 19.54,18.95 19.66,18.73L21.66,15.27C21.78,15.05 21.73,14.78 21.54,14.63L19.43,12.97Z"/>
                </svg>
                Usage Options
            </h2>
            
            <p>The script provides an interactive menu with these options:</p>
            
            <div class="options-list">
                <ol>
                    <li>Configure PHP version only</li>
                    <li>Install Node.js only</li>
                    <li>Fix permissions only</li>
                    <li>Complete setup (all three)</li>
                    <li>Exit</li>
                </ol>
            </div>
        </div>

        <div class="section">
            <h2>
                <svg class="icon" viewBox="0 0 24 24">
                    <path d="M21,7L9,19L3.5,13.5L4.91,12.09L9,16.17L19.59,5.59L21,7Z"/>
                </svg>
                Post-Installation
            </h2>
            
            <p>After running the script:</p>
            
            <div class="steps">
                <ul style="list-style: none; padding-left: 0;">
                    <li style="padding-left: 1.5rem; position: relative;">
                        <span style="position: absolute; left: 0; color: #4caf50; font-weight: bold;">•</span>
                        Restart your SSH session, or
                    </li>
                    <li style="padding-left: 1.5rem; position: relative;">
                        <span style="position: absolute; left: 0; color: #4caf50; font-weight: bold;">•</span>
                        Run <span class="highlight">source ~/.bashrc</span> to apply changes
                    </li>
                    <li style="padding-left: 1.5rem; position: relative;">
                        <span style="position: absolute; left: 0; color: #4caf50; font-weight: bold;">•</span>
                        For terminal users: open a new terminal window
                    </li>
                </ul>
            </div>
            
            <div class="code-block success-code">
The script automatically verifies the installation and displays version information.
            </div>
        </div>
    </div>
</body>
</html>