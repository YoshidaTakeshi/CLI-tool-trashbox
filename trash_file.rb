class TrashFile
  attr_accessor :abs_path, :last_access_date

  def initialize(original_path)
    @abs_path = set_abs_path(original_path)
    @last_access_date = set_last_access_date(original_path)
  end

  def move(destination_path)
    IO.popen("mv #{@abs_path} #{destination_path}")
  end

  private

  def set_abs_path(original_path)
    File.expand_path(original_path)
  end

  def set_last_access_date(original_path)
      IO
        .popen("ls -li #{original_path}") { |io| io.gets }
        .split(" ")[-4..-2]
  end
end
