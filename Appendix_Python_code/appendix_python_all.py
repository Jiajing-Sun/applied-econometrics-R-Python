"""兼容入口：从任意工作目录运行本版 Python 附录离线示例。"""
from pathlib import Path
import argparse
import os
import runpy


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-paths", action="store_true",
                        help="只检查配套代码根目录和目标文件，不执行示例")
    args = parser.parse_args()
    repo_root = Path(__file__).resolve().parents[1]
    target = repo_root / "补充示例" / "正文" / "appendix_Python_离线正文代码.py"
    if not target.is_file():
        raise FileNotFoundError(f"缺少最新版离线入口：{target}")
    if not (repo_root / "data" / "processed").is_dir():
        raise FileNotFoundError(f"缺少冻结数据目录：{repo_root / 'data' / 'processed'}")
    if args.check_paths:
        print(f"配套代码根目录：{repo_root}")
        print(f"离线入口：{target}")
        print("路径检查通过；未执行附录代码。")
        return
    os.chdir(repo_root)
    runpy.run_path(str(target), run_name="__main__")


if __name__ == "__main__":
    main()
