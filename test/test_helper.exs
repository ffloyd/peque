support_path = Path.expand("support", __DIR__)

Code.require_file("helpers.exs", support_path)
Code.require_file("shared.exs", support_path)

ExUnit.start()
