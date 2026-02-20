# frozen_string_literal: true

require "json"

baseline_path = ARGV[0] || "main-coverage/.resultset.json"
pr_path = ARGV[1] || "coverage/.resultset.json"
output_path = ARGV[2] || "coverage_comment.md"

unless File.exist?(pr_path)
  warn "PR coverage file not found: #{pr_path}"
  exit 2
end

baseline_exists = File.exist?(baseline_path)

baseline = baseline_exists ? JSON.parse(File.read(baseline_path)) : nil
pr = JSON.parse(File.read(pr_path))

def extract_run(payload)
  return nil unless payload.is_a?(Hash)

  payload.values.find { |v| v.is_a?(Hash) && v.key?("coverage") }
end

def total_line_coverage(run)
  coverage = run.fetch("coverage")

  total = 0
  covered = 0

  coverage.each_value do |file_cov|
    lines = if file_cov.is_a?(Hash) && file_cov.key?("lines")
              file_cov["lines"]
    else
      file_cov
    end

    Array(lines).each do |hit|
      next if hit.nil?

      total += 1
      covered += 1 if hit.to_i.positive?
    end
  end

  percent = total.positive? ? (covered.to_f / total * 100.0) : 0.0
  [percent, covered, total]
end

def total_branch_coverage(run)
  coverage = run.fetch("coverage")

  total = 0
  covered = 0

  coverage.each_value do |file_cov|
    next unless file_cov.is_a?(Hash)

    branches = file_cov["branches"]
    next unless branches.is_a?(Hash) && !branches.empty?

    branches.each_value do |branch_arms|
      next unless branch_arms.is_a?(Hash)

      branch_arms.each_value do |hits|
        next if hits.nil?

        total += 1
        covered += 1 if hits.to_i.positive?
      end
    end
  end

  percent = total.positive? ? (covered.to_f / total * 100.0) : 0.0
  [percent, covered, total]
end

baseline_run = extract_run(baseline)
pr_run = extract_run(pr)

unless pr_run
  warn "Could not find a SimpleCov run with coverage data in PR resultset."
  exit 3
end

pr_percent, pr_covered, pr_total = total_line_coverage(pr_run)
pr_branch_percent, pr_br_covered, pr_br_total = total_branch_coverage(pr_run)

if baseline_run
  base_percent, base_covered, base_total = total_line_coverage(baseline_run)
  base_branch_percent, base_br_covered, base_br_total = total_branch_coverage(baseline_run)
  diff = pr_percent - base_percent
  branch_diff = pr_branch_percent - base_branch_percent
else
  base_percent = nil
  base_covered = nil
  base_total = nil
  base_branch_percent = nil
  base_br_covered = nil
  base_br_total = nil
  diff = nil
  branch_diff = nil
end

status = if diff.nil?
           "ℹ️"
elsif diff >= 0
  "✅"
else
  "❌"
end

lines = []
lines << "## Coverage Report"
lines <<
  if base_percent
    "Main: #{format('%.2f', base_percent)}% (#{base_covered}/#{base_total})"
  else
    "Main: (baseline not available)"
  end
lines << "PR: #{format('%.2f', pr_percent)}% (#{pr_covered}/#{pr_total})"

lines <<
  if base_branch_percent
    "Main (branches): #{format('%.2f', base_branch_percent)}% (#{base_br_covered}/#{base_br_total})"
  else
    "Main (branches): (baseline not available)"
  end
lines << "PR (branches): #{format('%.2f', pr_branch_percent)}% (#{pr_br_covered}/#{pr_br_total})"

if diff
  lines << ""
  lines << "Difference: #{status} #{'+' if diff >= 0}#{format('%.2f', diff)}%"
end

if branch_diff
  branch_status = branch_diff >= 0 ? "✅" : "❌"
  lines << "Branch difference: #{branch_status} #{'+' if branch_diff >= 0}#{format('%.2f', branch_diff)}%"
end

File.write(output_path, lines.join("\n") + "\n")

# Fail the job if coverage dropped compared to main.
if diff && diff < 0
  warn "Coverage decreased by #{format('%.2f', diff.abs)}%"
  exit 1
end

if branch_diff && branch_diff < 0
  warn "Branch coverage decreased by #{format('%.2f', branch_diff.abs)}%"
  exit 1
end
