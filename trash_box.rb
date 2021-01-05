require "csv"
require "./trash_file.rb"

class TrashBox
  HEADERS = ["month", "day", "time", "original_path"]
  THROW_OUT_LOG_PATH = "/trashbox/throw_away_log.csv"
  TRASHBOX_PATH = "/trashbox"
  EXEPTION_CONDITION = "! -path \"*/trashbox/*\" ! -path \"*/.*\" ! -name \"throw_away_log.csv\""

  def initialize(action = "", directory_path = "", days = 30)
    @trash_files = set_trash_files(action, directory_path, days)
    @directory_path = directory_path
    @action = action
  end

  def run_action
    case @action
    when "throw"
      throw_away_trash_files
    when "reset"
      reset
    end
  end

  def show_usage
    puts <<~ESO
      You can collect files that have not been accessed for a input number of days.
      usage   : ruby trash_box.rb <action> <directory_path> <number_of_days>
      actions : [throw]  Create a trashbox under the input directory and collect old files.
                [reset]  Put the collected files back in their original path.
    ESO
  end

  private

  def set_trash_files(action, directory_path, days)
    case action
    when "throw"
      find_trash_files(directory_path, days)
    when "reset"
      find_trash_files(directory_path + TRASHBOX_PATH, days)
    end
  end

  def find_trash_files(directory_path, days)
    raise "such directory does not exist" if Dir.exist?("#{@directory_path}")

    IO
      .popen("find #{directory_path} -type f -atime ! -#{days} #{EXEPTION_CONDITION}") { |io|
       io.readlines
      }
      .map { |file_path| TrashFile.new(file_path.strip) }
  end

  def make_directory
    Dir.mkdir("#{@directory_path}#{TRASHBOX_PATH}")
  end

    def create_log
    CSV.open("#{@directory_path}#{THROW_OUT_LOG_PATH}", "a") do |file|
      file.puts HEADERS
      @trash_files.each do |trash_file|
        file.puts trash_file.last_access_date + [trash_file.abs_path]
      end
    end
  end

  def throw_away_trash_files
    make_directory if !Dir.exist?("#{@directory_path}#{TRASHBOX_PATH}")
    create_log
    @trash_files.each { |trash_file| trash_file.move("#{@directory_path}#{TRASHBOX_PATH}") }
  end

  # def reset
  #   raise "log file does not exist" if !File.exist?("#{@directory_path}#{THROW_OUT_LOG_PATH}")
  #   raise "trashbox is not exist" if !Dir.exist?("#{@directory_path}#{TRASHBOX_PATH}")

  #   CSV
  #     .table("#{@directory_path}#{THROW_OUT_LOG_PATH}")[:original_path]
  #     .map { |original_path| File.dirname(original_path) }
  #     .zip(@trash_files)
  #     .each do |path_and_file|
  #       path_and_file[1].move(path_and_file[0])
  #     end
  #     delete_log
  #     delete_directory
  # end

  # def delete_log
  #   IO.popen("rm #{@directory_path}#{THROW_OUT_LOG_PATH}")
  # end

  # def delete_directory
  #   raise "trashbox is not empty" if !Dir.empty?("#{@directory_path}#{TRASHBOX_PATH}")

  #   Dir.delete("#{@directory_path}#{TRASHBOX_PATH}")
  # end
end

if __FILE__ == $0
  if ARGV[0] != "throw" && ARGV[0] != "reset"
    TrashBox.new().show_usage
    raise "input correct argument"
  end

  p TrashBox.new(ARGV[0], ARGV[1], ARGV[2]) 
  TrashBox.new(ARGV[0], ARGV[1], ARGV[2]).run_action
end
