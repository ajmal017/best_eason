class Hash
  def has_all_array_values?
      values.all? { |k| Array === k }
  end
end