import { showToast, Toast, getSelectedFinderItems } from "@raycast/api";
import { exec } from "child_process";
import { promisify } from "util";

const execAsync = promisify(exec);

export default async function Command() {
  try {
    // Get selected files from Finder
    const selectedItems = await getSelectedFinderItems();
    
    if (selectedItems.length === 0) {
      await showToast({
        style: Toast.Style.Failure,
        title: "No file selected",
        message: "Please select a markdown file in Finder",
      });
      return;
    }

    // Filter for markdown files
    const markdownFiles = selectedItems.filter((item) => {
      const ext = item.path.toLowerCase().split(".").pop();
      return ["md", "markdown", "mdown", "mkd"].includes(ext || "");
    });

    if (markdownFiles.length === 0) {
      await showToast({
        style: Toast.Style.Failure,
        title: "No markdown files",
        message: "Selected files are not markdown files",
      });
      return;
    }

    // Open each file in Parchment
    for (const file of markdownFiles) {
      await execAsync(`open -a Parchment "${file.path}"`);
    }

    await showToast({
      style: Toast.Style.Success,
      title: "Opened in Parchment",
      message: `${markdownFiles.length} file(s) opened`,
    });
  } catch (error) {
    await showToast({
      style: Toast.Style.Failure,
      title: "Failed to open",
      message: error instanceof Error ? error.message : "Unknown error",
    });
  }
}
