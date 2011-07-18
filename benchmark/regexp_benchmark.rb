require File.expand_path('../benchmark_helper', __FILE__)

class RegexpBenchmark < Test::Unit::TestCase
  include Benchmark

  def test_inclusive_vs_exclusive_regexp
    n = 100000
    inclusive = /\A((-{1,2})\w.*?)(?:(?:=|\s+)(.*))?\z/
    exclusive = /\A((-{1,2})\w[^=\s]*)=?\s*(.+)?\z/

    optword = /\w[^=\s]*?/
    interpolated = /\A((-{1,2})#{optword})(?:[=\s]\s*(.*))?\z/
    literal = /\A((-{1,2})\w[^=\s]*?)(?:[=\s]\s*(.*))?\z/

    bm(30) do |x|
      x.report "inclusive regexp" do
        n.times { '--long' =~ inclusive }
      end

      x.report "inclusive regexp =VALUE" do
        n.times { '--long=VALUE' =~ inclusive }
      end

      x.report "inclusive regexp VALUE" do
        n.times { '--long VALUE' =~ inclusive }
      end

      x.report "exclusive regexp" do
        n.times { '--long' =~ exclusive }
      end

      x.report "exclusive regexp =VALUE" do
        n.times { '--long=VALUE' =~ exclusive }
      end

      x.report "exclusive regexp VALUE" do
        n.times { '--long VALUE' =~ exclusive }
      end

      x.report "interpolated regexp" do
        n.times { '--long' =~ interpolated }
      end

      x.report "interpolated regexp =VALUE" do
        n.times { '--long=VALUE' =~ interpolated }
      end

      x.report "interpolated regexp VALUE" do
        n.times { '--long VALUE' =~ interpolated }
      end

      x.report "literal regexp" do
        n.times { '--long' =~ literal }
      end

      x.report "literal regexp =VALUE" do
        n.times { '--long=VALUE' =~ literal }
      end

      x.report "literal regexp VALUE" do
        n.times { '--long VALUE' =~ literal }
      end
    end
  end
end
