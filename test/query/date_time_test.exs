defmodule DateTimeTest do
  use ExUnit.Case, async: false
  use RethinkDB.Connection
  import RethinkDB.Query

  alias RethinkDB.Record
  alias RethinkDB.Pseudotypes.Time

  setup_all do
    start_link()
    :ok
  end

  test "now native" do
    {:ok, %Record{data: data}} = now() |> run
    assert %DateTime{} = data
  end

  test "now raw" do
    {:ok, %Record{data: data}} = now() |> run(time_format: :raw)
    assert %Time{} = data
  end

  test "time native" do
    {:ok, %Record{data: data}} = time(1970, 1, 1, "Z") |> run
    assert data == DateTime.from_unix!(0, :millisecond)
    {:ok, %Record{data: data}} = time(1970, 1, 1, 0, 0, 1, "Z") |> run(binary_format: :native)
    assert data == DateTime.from_unix!(1000, :millisecond)
  end

  test "time raw" do
    {:ok, %Record{data: data}} = time(1970, 1, 1, "Z") |> run(time_format: :raw)
    assert data.epoch_time == 0
    {:ok, %Record{data: data}} = time(1970, 1, 1, 0, 0, 1, "Z") |> run(time_format: :raw)
    assert data.epoch_time == 1
  end

  test "epoch_time native" do
    {:ok, %Record{data: data}} = epoch_time(1) |> run
    assert data == DateTime.from_unix!(1000, :millisecond)
  end

  test "epoch_time raw" do
    {:ok, %Record{data: data}} = epoch_time(1) |> run(time_format: :raw)
    assert data.epoch_time == 1
    assert data.timezone == "+00:00"
  end

  test "iso8601 native" do
    {:ok, %Record{data: data}} = iso8601("1970-01-01T00:00:00+00:00") |> run
    assert data == DateTime.from_unix!(0, :millisecond)
    {:ok, %Record{data: data}} = iso8601("1970-01-01T00:00:00", default_timezone: "+01:00") |> run

    assert data ==
             DateTime.from_unix!(-3_600_000, :millisecond)
             |> struct(utc_offset: 3600, time_zone: "Etc/GMT-1", zone_abbr: "+01")
  end

  test "iso8601 raw" do
    {:ok, %Record{data: data}} = iso8601("1970-01-01T00:00:00+00:00") |> run(time_format: :raw)
    assert data.epoch_time == 0
    assert data.timezone == "+00:00"

    {:ok, %Record{data: data}} =
      iso8601("1970-01-01T00:00:00", default_timezone: "+01:00") |> run(time_format: :raw)

    assert data.epoch_time == -3600
    assert data.timezone == "+01:00"
  end

  test "in_timezone native" do
    {:ok, %Record{data: data}} = epoch_time(0) |> in_timezone("+01:00") |> run

    assert data ==
             DateTime.from_unix!(0, :millisecond)
             |> struct(utc_offset: 3600, time_zone: "Etc/GMT-1", zone_abbr: "+01")
  end

  test "in_timezone raw" do
    {:ok, %Record{data: data}} = epoch_time(0) |> in_timezone("+01:00") |> run(time_format: :raw)
    assert data.timezone == "+01:00"
    assert data.epoch_time == 0
  end

  test "timezone" do
    {:ok, %Record{data: data}} = %Time{epoch_time: 0, timezone: "+01:00"} |> timezone |> run
    assert data == "+01:00"
  end

  test "during" do
    a = epoch_time(5)
    b = epoch_time(10)
    c = epoch_time(7)
    {:ok, %Record{data: data}} = c |> during(a, b) |> run
    assert data == true
    {:ok, %Record{data: data}} = b |> during(a, c) |> run
    assert data == false
  end

  test "date native" do
    {:ok, %Record{data: data}} = epoch_time(5) |> date |> run
    assert data == DateTime.from_unix!(0, :millisecond)
  end

  test "date raw" do
    {:ok, %Record{data: data}} = epoch_time(5) |> date |> run(time_format: :raw)
    assert data.epoch_time == 0
  end

  test "time_of_day" do
    {:ok, %Record{data: data}} = epoch_time(60 * 60 * 24 + 15) |> time_of_day |> run
    assert data == 15
  end

  test "year" do
    {:ok, %Record{data: data}} = epoch_time(2 * 365 * 60 * 60 * 24) |> year |> run
    assert data == 1972
  end

  test "month" do
    {:ok, %Record{data: data}} = epoch_time(2 * 30 * 60 * 60 * 24) |> month |> run
    assert data == 3
  end

  test "day" do
    {:ok, %Record{data: data}} = epoch_time(3 * 60 * 60 * 24) |> day |> run
    assert data == 4
  end

  test "day_of_week" do
    {:ok, %Record{data: data}} = epoch_time(3 * 60 * 60 * 24) |> day_of_week |> run
    assert data == 7
  end

  test "day_of_year" do
    {:ok, %Record{data: data}} = epoch_time(3 * 60 * 60 * 24) |> day_of_year |> run
    assert data == 4
  end

  test "hours" do
    {:ok, %Record{data: data}} = epoch_time(3 * 60 * 60) |> hours |> run
    assert data == 3
  end

  test "minutes" do
    {:ok, %Record{data: data}} = epoch_time(3 * 60) |> minutes |> run
    assert data == 3
  end

  test "seconds" do
    {:ok, %Record{data: data}} = epoch_time(3) |> seconds |> run
    assert data == 3
  end

  test "to_iso8601" do
    {:ok, %Record{data: data}} = epoch_time(3) |> to_iso8601 |> run
    assert data == "1970-01-01T00:00:03+00:00"
  end

  test "to_epoch_time" do
    {:ok, %Record{data: data}} = epoch_time(3) |> to_epoch_time |> run
    assert data == 3
  end
end
