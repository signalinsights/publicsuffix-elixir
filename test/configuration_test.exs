defmodule PublicSuffix.ConfigurationTest do
  use ExUnit.Case
  @data_file_name "public_suffix_list.dat"
  @cached_data_dir Path.expand("../data", __DIR__)

  @moduletag :tmp_dir

  setup(%{tmp_dir: tmp_dir}) do
    cached_file_name = Path.join(@cached_data_dir, @data_file_name)
    backup_file_name = Path.join(tmp_dir, @data_file_name)

    File.cp!(cached_file_name, backup_file_name)

    modified_rules =
      cached_file_name
      |> File.read!()
      |> Kernel.<>("\npublicsuffix.elixir")

    File.write!(cached_file_name, modified_rules)

    on_exit(fn ->
      # restore things...
      recompile_lib()
      File.cp!(backup_file_name, cached_file_name)
      File.rm_rf!(tmp_dir)
    end)
  end

  test "compiles using a newly fetched copy of the rules file if so configured" do
    recompile_lib()
    assert get_public_suffix("foo.publicsuffix.elixir") == "publicsuffix.elixir"
    recompile_lib([{"PUBLIC_SUFFIX_DOWNLOAD_DATA_ON_COMPILE", "true"}])
    assert get_public_suffix("foo.publicsuffix.elixir") == "elixir"
  end

  defp get_public_suffix(domain) do
    expression = "#{inspect(domain)} |> PublicSuffix.public_suffix |> IO.puts"
    assert {result, 0} = System.cmd("mix", ["run", "-e", expression])
    result |> String.trim() |> String.split("\n") |> List.last()
  end

  defp recompile_lib(env \\ []) do
    assert {_output, 0} = System.cmd("mix", ["compile", "--force"], env: env)
  end
end
