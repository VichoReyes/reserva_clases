defmodule ReservaClases.Calendar do
  def strftime(time, format) do
    month_names =
      {"Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre",
       "Octubre", "Noviembre", "Diciembre"}

    day_of_week_names = {"Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"}

    Calendar.strftime(
      time,
      format,
      month_names: &elem(month_names, &1 - 1),
      day_of_week_names: &elem(day_of_week_names, &1 - 1)
    )
  end
end
