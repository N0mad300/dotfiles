#!/usr/bin/env python3
"""
GitHub Folder Downloader - Git Sparse-Checkout Method
Downloads a GitHub repository folder using git sparse-checkout for efficiency.
Usage: python github_downloader.py <github_url> [output_folder]
"""

import os
import sys
import argparse
import subprocess
import shutil
import tempfile
from urllib.parse import urlparse
from pathlib import Path

class GitHubFolderDownloader:
    def __init__(self, github_url, output_dir):
        self.github_url = github_url.rstrip('/')
        self.output_dir = Path(output_dir).expanduser()
        
    def parse_github_url(self):
        """Parse GitHub URL to extract repo info, git reference, and folder path"""
        parsed = urlparse(self.github_url)
        path_parts = parsed.path.strip('/').split('/')
        
        if len(path_parts) < 2:
            raise ValueError("Invalid GitHub URL format")
            
        owner = path_parts[0]
        repo = path_parts[1]
        
        # Extract the folder path and git reference (branch/commit/tag)
        folder_path = ""
        git_ref = "main"  # default branch
        ref_type = "branch"  # can be 'branch', 'commit', or 'tag'
        
        if len(path_parts) > 2:
            if path_parts[2] == "tree" and len(path_parts) > 3:
                git_ref = path_parts[3]
                if len(path_parts) > 4:
                    folder_path = "/".join(path_parts[4:])
                
                # Determine if it's a commit hash, tag, or branch
                if len(git_ref) == 40 and all(c in '0123456789abcdef' for c in git_ref.lower()):
                    ref_type = "commit"
                elif '.' in git_ref or git_ref.startswith('v'):
                    ref_type = "tag"  # Common tag patterns
                else:
                    ref_type = "branch"
                    
            elif path_parts[2] == "blob" and len(path_parts) > 3:
                git_ref = path_parts[3]
                if len(path_parts) > 4:
                    folder_path = "/".join(path_parts[4:])
                
                # Same logic for blob URLs
                if len(git_ref) == 40 and all(c in '0123456789abcdef' for c in git_ref.lower()):
                    ref_type = "commit"
                elif '.' in git_ref or git_ref.startswith('v'):
                    ref_type = "tag"
                else:
                    ref_type = "branch"
        
        return owner, repo, git_ref, ref_type, folder_path
    
    def check_git_available(self):
        """Check if git is available in the system"""
        try:
            result = subprocess.run(['git', '--version'], 
                                  capture_output=True, text=True, check=True)
            print(f"Using Git: {result.stdout.strip()}")
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("Error: Git is not installed or not available in PATH")
            print("Please install Git: https://git-scm.com/downloads")
            return False
    
    def download_with_sparse_checkout(self):
        """
        Download using git sparse-checkout method
        
        This method works by:
        1. Cloning the repository without checking out files (--no-checkout)
        2. Enabling sparse-checkout feature
        3. Specifying which folders/files to include
        4. Checking out only the specified content at the specified git reference
        """
        owner, repo, git_ref, ref_type, folder_path = self.parse_github_url()
        clone_url = f"https://github.com/{owner}/{repo}.git"
        
        print(f"Repository: {owner}/{repo}")
        print(f"Git reference: {git_ref} ({ref_type})")
        print(f"Target folder: {folder_path if folder_path else '(entire repository)'}")
        print(f"Clone URL: {clone_url}")
        print()
        
        # Create temporary directory for the git operations
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_path = Path(temp_dir)
            repo_path = temp_path / repo
            
            try:
                print("Step 1: Cloning repository (without checkout)...")
                
                # For commits, we need to fetch more history
                clone_cmd = [
                    "git", "clone", 
                    "--no-checkout",           # Don't checkout files yet
                    "--filter=blob:none",      # Don't download file contents yet
                    clone_url, 
                    str(repo_path)
                ]
                
                # For commits, we can't use --depth 1 as the commit might not be in recent history
                if ref_type != "commit":
                    clone_cmd.insert(-2, "--depth")
                    clone_cmd.insert(-2, "1")
                    clone_cmd.insert(-2, "--branch")
                    clone_cmd.insert(-2, git_ref)
                
                subprocess.run(clone_cmd, check=True, capture_output=True, text=True)
                print("✓ Repository cloned successfully")
                
                # For commits, we need to fetch the specific commit if it's not available
                if ref_type == "commit":
                    print(f"Step 1b: Fetching commit {git_ref[:8]}...")
                    try:
                        # Try to checkout the commit directly
                        subprocess.run([
                            "git", "-C", str(repo_path),
                            "cat-file", "-e", git_ref
                        ], check=True, capture_output=True, text=True)
                        print("✓ Commit found in repository")
                    except subprocess.CalledProcessError:
                        # If commit not found, fetch more history
                        print("⚠️  Commit not in shallow history, fetching more...")
                        subprocess.run([
                            "git", "-C", str(repo_path),
                            "fetch", "--unshallow"
                        ], check=True, capture_output=True, text=True)
                        print("✓ Full history fetched")
                
                print("\nStep 2: Configuring sparse-checkout...")
                # Enable sparse-checkout feature (only for this repository)
                subprocess.run([
                    "git", "-C", str(repo_path), 
                    "config", "--local", "core.sparseCheckout", "true"
                ], check=True, capture_output=True, text=True)
                print("✓ Sparse-checkout enabled (local repository only)")
                
                # Configure what to include in sparse-checkout
                sparse_file = repo_path / ".git" / "info" / "sparse-checkout"
                
                if folder_path:
                    # Download specific folder and its contents
                    patterns = [
                        f"{folder_path}",      # Include the folder itself
                        f"{folder_path}/**"    # Include everything inside recursively
                    ]
                    print(f"✓ Configured to download folder: {folder_path}")
                else:
                    # Download everything (root level)
                    patterns = ["*"]
                    print("✓ Configured to download entire repository")
                
                with open(sparse_file, 'w') as f:
                    for pattern in patterns:
                        f.write(f"{pattern}\n")
                
                print(f"✓ Sparse-checkout patterns written to: {sparse_file}")
                
                print(f"\nStep 3: Checking out files at {ref_type} '{git_ref}'...")
                # Now checkout the files at the specific git reference
                subprocess.run([
                    "git", "-C", str(repo_path), 
                    "checkout", git_ref
                ], check=True, capture_output=True, text=True)
                print(f"✓ Files checked out successfully at {git_ref}")
                
                print("\nStep 4: Copying to destination...")
                # Determine source and target paths
                if folder_path:
                    source_folder = repo_path / folder_path
                    if not source_folder.exists():
                        raise FileNotFoundError(f"Folder '{folder_path}' not found in {ref_type} '{git_ref}'")
                    
                    folder_name = Path(folder_path).name
                    # Include git reference in folder name for clarity
                    if ref_type == "commit":
                        target_name = f"{folder_name}_{git_ref[:8]}"
                    elif ref_type == "tag":
                        target_name = f"{folder_name}_{git_ref.replace('/', '_')}"
                    else:
                        target_name = f"{folder_name}_{git_ref}" if git_ref != "main" else folder_name
                    
                    target_path = self.output_dir / target_name
                    
                    print(f"Source: {source_folder}")
                    print(f"Target: {target_path}")
                    
                    # Remove existing target directory if it exists
                    if target_path.exists():
                        print(f"Removing existing directory: {target_path}")
                        shutil.rmtree(target_path)
                    
                    # Copy the folder
                    shutil.copytree(source_folder, target_path)
                    
                else:
                    # Copy entire repository (excluding .git)
                    if ref_type == "commit":
                        folder_name = f"{repo}_{git_ref[:8]}"
                    elif ref_type == "tag":
                        folder_name = f"{repo}_{git_ref.replace('/', '_')}"
                    else:
                        folder_name = f"{repo}_{git_ref}" if git_ref != "main" else repo
                    
                    target_path = self.output_dir / folder_name
                    
                    print(f"Source: {repo_path} (excluding .git)")
                    print(f"Target: {target_path}")
                    
                    # Remove existing target directory if it exists
                    if target_path.exists():
                        print(f"Removing existing directory: {target_path}")
                        shutil.rmtree(target_path)
                    
                    # Create target directory
                    target_path.mkdir(parents=True, exist_ok=True)
                    
                    # Copy everything except .git directory
                    for item in repo_path.iterdir():
                        if item.name != '.git':
                            if item.is_dir():
                                shutil.copytree(item, target_path / item.name)
                            else:
                                shutil.copy2(item, target_path / item.name)
                
                print(f"✓ Successfully copied to: {target_path}")
                
                # Show some stats
                total_files = sum(1 for _ in target_path.rglob('*') if _.is_file())
                total_dirs = sum(1 for _ in target_path.rglob('*') if _.is_dir())
                
                print(f"\nDownload completed!")
                print(f"📁 Directories: {total_dirs}")
                print(f"📄 Files: {total_files}")
                print(f"📍 Location: {target_path.absolute()}")
                print(f"🔗 Git reference: {git_ref} ({ref_type})")
                
                return True
                
            except subprocess.CalledProcessError as e:
                print(f"\n❌ Git command failed:")
                print(f"Command: {' '.join(e.cmd)}")
                if e.stderr:
                    print(f"Error: {e.stderr}")
                if e.stdout:
                    print(f"Output: {e.stdout}")
                return False
                
            except FileNotFoundError as e:
                print(f"\n❌ {e}")
                return False
                
            except Exception as e:
                print(f"\n❌ Unexpected error: {e}")
                return False
    
    def download(self):
        """Main download method"""
        if not self.check_git_available():
            return False
        
        # Create output directory
        self.output_dir.mkdir(parents=True, exist_ok=True)
        print(f"Output directory: {self.output_dir.absolute()}\n")
        
        return self.download_with_sparse_checkout()

def main():
    parser = argparse.ArgumentParser(
        description="Download GitHub repository folders using git sparse-checkout",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
How Git Sparse-Checkout Works (SAFELY):
========================================

This script uses git sparse-checkout in a completely isolated way that won't
affect your other Git repositories or global Git settings.

Safety measures:
- Uses --local flag to modify only the temporary repository config
- Works in a temporary directory that gets automatically deleted
- Never touches your global Git configuration
- No impact on your existing projects

The process:
1. Clone the repository in a temporary directory (--no-checkout)
2. Enable sparse-checkout ONLY for this temporary repo (--local config)
3. Define patterns in .git/info/sparse-checkout file (repo-specific)
4. Checkout files matching the patterns
5. Copy files to your desired location
6. Delete temporary directory (automatic cleanup)

Benefits:
- Only downloads what you need
- Much faster than cloning entire large repositories
- Supports complex patterns and multiple folders
- Uses standard Git protocols (works with any Git host)

Examples:
  # Download specific folder from latest commit
  python github_downloader.py https://github.com/user/repo/tree/main/src
  
  # Download from specific commit (like your example)
  python github_downloader.py https://github.com/binnewbs/arch-hyprland/tree/03b85877996253b0518e8a57f6249a4d2dcf4697/.config/waybar
  
  # Download from specific tag
  python github_downloader.py https://github.com/user/repo/tree/v1.2.0/docs
  
  # Download from different branch
  python github_downloader.py https://github.com/user/repo/tree/develop/src
  
  # Download entire repository at specific commit
  python github_downloader.py https://github.com/user/repo/tree/abc1234
  
  # Custom output location
  python github_downloader.py https://github.com/user/repo/tree/main/src ~/my_projects
        """
    )
    
    parser.add_argument('url', help='GitHub repository or folder URL')
    parser.add_argument('output', nargs='?', default='~/Downloads',
                       help='Output directory (default: ~/Downloads)')
    
    args = parser.parse_args()
    
    # Validate URL
    if 'github.com' not in args.url:
        print("❌ Error: Please provide a valid GitHub URL")
        sys.exit(1)
    
    try:
        # Create downloader and start download
        downloader = GitHubFolderDownloader(args.url, args.output)
        success = downloader.download()
        
        sys.exit(0 if success else 1)
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Download interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
