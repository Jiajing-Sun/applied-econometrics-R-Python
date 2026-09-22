# 兼容入口：从任意工作目录运行本版 R 附录离线示例。
# Rscript /完整路径/appendix_R_program_all.R
# 加 --check-paths 只检查根目录和目标文件，不执行示例。
run_appendix_offline <- function() {
  # 同时支持 Rscript 与 source("完整路径")。
  source_paths <- vapply(sys.frames(), function(frame) {
    if (is.null(frame$ofile)) "" else as.character(frame$ofile)[1]
  }, character(1))
  source_paths <- source_paths[nzchar(source_paths)]
  if (length(source_paths)) {
    script_path <- tail(source_paths, 1)
  } else {
    args <- commandArgs(trailingOnly = FALSE)
    file_arg <- args[startsWith(args, "--file=")]
    if (!length(file_arg)) stop("请用 Rscript 或 source() 运行本入口。")
    script_path <- sub("^--file=", "", file_arg[1])
  }
  # Rscript 在部分平台会用 ~+~ 表示命令参数中的空格。
  script_path <- gsub("~+~", " ", script_path, fixed = TRUE)
  repo_root <- dirname(dirname(normalizePath(script_path, mustWork = TRUE)))
  target <- file.path(repo_root, "补充示例", "正文",
                      "appendix_R_离线正文代码.R")
  if (!file.exists(target)) stop("缺少最新版离线入口：", target)
  if (!dir.exists(file.path(repo_root, "data", "processed"))) {
    stop("缺少冻结数据目录：", file.path(repo_root, "data", "processed"))
  }
  if ("--check-paths" %in% commandArgs(trailingOnly = TRUE)) {
    cat("配套代码根目录：", repo_root, "\n",
        "离线入口：", target, "\n",
        "路径检查通过；未执行附录代码。\n", sep = "")
    return(invisible(list(root = repo_root, target = target)))
  }
  previous_wd <- getwd()
  on.exit(setwd(previous_wd), add = TRUE)
  setwd(repo_root)
  source(target, local = .GlobalEnv, chdir = FALSE)
}
run_appendix_offline()
