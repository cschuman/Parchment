import { ActionPanel, Action, List, showToast, Toast } from "@raycast/api";
import { exec } from "child_process";
import { promisify } from "util";
import { useState, useEffect } from "react";

const execAsync = promisify(exec);

interface RecentFile {
  path: string;
  name: string;
  modTime: Date;
}

export default function Command() {
  const [files, setFiles] = useState<RecentFile[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    async function fetchRecentFiles() {
      try {
        // Find recently modified markdown files
        const { stdout } = await execAsync(
          `find ~ -name "*.md" -type f -mtime -7 2>/dev/null | head -50`
        );
        
        const paths = stdout.trim().split("\n").filter(Boolean);
        const recentFiles: RecentFile[] = paths.map((path) => ({
          path,
          name: path.split("/").pop() || path,
          modTime: new Date(),
        }));

        setFiles(recentFiles);
      } catch (error) {
        console.error("Error fetching files:", error);
      } finally {
        setIsLoading(false);
      }
    }

    fetchRecentFiles();
  }, []);

  async function openInParchment(path: string) {
    try {
      await execAsync(`open -a Parchment "${path}"`);
      await showToast({
        style: Toast.Style.Success,
        title: "Opened in Parchment",
      });
    } catch (error) {
      await showToast({
        style: Toast.Style.Failure,
        title: "Failed to open",
        message: error instanceof Error ? error.message : "Unknown error",
      });
    }
  }

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search recent markdown files...">
      {files.map((file) => (
        <List.Item
          key={file.path}
          title={file.name}
          subtitle={file.path}
          actions={
            <ActionPanel>
              <Action title="Open in Parchment" onAction={() => openInParchment(file.path)} />
              <Action.ShowInFinder path={file.path} />
              <Action.CopyToClipboard content={file.path} title="Copy Path" />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
