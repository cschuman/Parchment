import * as vscode from 'vscode';
import { exec, execSync } from 'child_process';
import * as path from 'path';

export function activate(context: vscode.ExtensionContext) {
    console.log('Parchment Preview extension is now active');

    // Check if Parchment is installed
    checkParchmentInstalled();

    // Register the open command
    const openCommand = vscode.commands.registerCommand('parchment.openInParchment', () => {
        openInParchment(false);
    });

    // Register the open in new window command
    const openNewWindowCommand = vscode.commands.registerCommand('parchment.openInParchmentNewWindow', () => {
        openInParchment(true);
    });

    context.subscriptions.push(openCommand, openNewWindowCommand);
}

function checkParchmentInstalled(): void {
    try {
        execSync('which parchment || test -d "/Applications/Parchment.app"', { encoding: 'utf8' });
    } catch {
        vscode.window.showWarningMessage(
            'Parchment is not installed. Install it with: brew install --cask parchment',
            'Install with Homebrew'
        ).then(selection => {
            if (selection === 'Install with Homebrew') {
                const terminal = vscode.window.createTerminal('Install Parchment');
                terminal.show();
                terminal.sendText('brew install --cask parchment');
            }
        });
    }
}

function openInParchment(newWindow: boolean): void {
    // Get the file path - from active editor or selected file
    let filePath: string | undefined;

    // Check if called from explorer context menu
    const activeEditor = vscode.window.activeTextEditor;
    if (activeEditor && activeEditor.document.languageId === 'markdown') {
        filePath = activeEditor.document.uri.fsPath;
    }

    if (!filePath) {
        vscode.window.showErrorMessage('No markdown file is currently open');
        return;
    }

    // Build the command
    let command: string;
    if (newWindow) {
        command = `open -n -a Parchment "${filePath}"`;
    } else {
        command = `open -a Parchment "${filePath}"`;
    }

    exec(command, (error, stdout, stderr) => {
        if (error) {
            // Try with the CLI if app isn't found
            const cliCommand = newWindow 
                ? `parchment --new-window "${filePath}"`
                : `parchment "${filePath}"`;
            
            exec(cliCommand, (cliError) => {
                if (cliError) {
                    vscode.window.showErrorMessage(
                        'Failed to open Parchment. Is it installed?',
                        'Install with Homebrew'
                    ).then(selection => {
                        if (selection === 'Install with Homebrew') {
                            const terminal = vscode.window.createTerminal('Install Parchment');
                            terminal.show();
                            terminal.sendText('brew install --cask parchment');
                        }
                    });
                }
            });
        }
    });
}

// Handle opening from explorer context menu
vscode.commands.registerCommand('parchment.openFromExplorer', (uri: vscode.Uri) => {
    if (uri && uri.fsPath) {
        const command = `open -a Parchment "${uri.fsPath}"`;
        exec(command, (error) => {
            if (error) {
                vscode.window.showErrorMessage('Failed to open file in Parchment');
            }
        });
    }
});

export function deactivate() {}
