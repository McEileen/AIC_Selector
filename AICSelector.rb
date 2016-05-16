#!/usr/bin/env ruby
require "csv"

class ProgramMatchRanker
  attr_reader :final_matches, :matches_to_find, :student_file, :program_file, :output_file

  UNRANKED_STUDENT_COLUMNS = {
    12 => "Artmaking", 13 => "Audio/Music Production", 14 => "Drawing/Graphic Design", 15 => "Digital/Video Production", 16 => "Storytelling"
  }

  PROGRAM_COLUMNS = {
    25 => "Artmaking", 26 => "Drawing/Graphic Design",
    27 => "Digital/Video Production", 28 => "Storytelling",
    29 => "Audio/Music Production"
  }

  def initialize(matches_to_find, student_file, program_file, output_file)
    @matches_to_find = matches_to_find
    @student_file = student_file
    @program_file = program_file
    @output_file = output_file
  end


  def read_students
    students = []
    spreadsheet = File.read(@student_file).encode("utf-8", invalid: :replace)
    rows = CSV.parse(spreadsheet)
    rows.each { |row| students << parse_student(row) }
    students
  end

  def read_programs
    programs = []
    spreadsheet = File.read(@program_file).encode("utf-8", invalid: :replace)
    rows = CSV.parse(spreadsheet)
    rows.each { |row| programs << parse_program(row) }
    programs
  end

  def parse_student(line)
    student = { interests: [] }
    student[:id] = line[0]
    UNRANKED_STUDENT_COLUMNS.each do |index, interest|
      if line[index]
        student[:interests] << interest
      end
    end
    student[:interests] = student[:interests].uniq
    student
  end

  def parse_program(line)
    program = { interests: [], name: line[10], organization: line[1], url: line[11], description: line[30] }
    PROGRAM_COLUMNS.each do |index, interest|
      if line[index]
        program[:interests] << interest
      end
    end
    program[:interests] = program[:interests].uniq
    program
  end

  def rank_matches(student, programs)
    priority_matches = []
    second_matches = []
    programs.each do |program|
      if program[:interests] == student[:interests]
        priority_matches << program
      end
    end
    second_matches = programs[1..-1].shuffle.sort_by do |program|
      program[:interests].select {|program_interest| student[:interests].include?(program_interest)}.length
    end
    second_matches = (second_matches - priority_matches).reverse!
    while (second_matches + priority_matches).length > @matches_to_find
      second_matches = second_matches[0..-2]
    end
    @final_matches = priority_matches + second_matches
  end

  def rank_matches_names(student, programs)
    rank_matches(student, programs)
    final_matches_names = @final_matches.map {|program| program[:name]}
  end

  def rank_matches_organizations(student, programs)
    p final_matches_organizations = @final_matches.map {|program| program[:organization]}
  end

  def rank_matches_urls(student, programs)
    final_matches_urls = @final_matches.map {|program| program[:url]}
  end

  def rank_matches_descriptions(student, programs)
    final_matches_descriptions = @final_matches.map {|program| program[:description]}
  end

  def match_programs_to_students
    students = read_students
    programs = read_programs
    students.each do |student|
      student[:matches_names] = rank_matches_names(student, programs)
      student[:matches_organizations] = rank_matches_organizations(student, programs)
      student[:matches_urls] = rank_matches_urls(student, programs)
      student[:matches_descriptions] = rank_matches_descriptions(student, programs)
    end
    students
  end

  def write_csv(students)
    CSV.open(@output_file, 'wb') do |csv|
      students.each do |student|
        csv << ([student[:id]] + student[:matches_names] + student[:matches_organizations] + student[:matches_urls]) + student[:matches_descriptions]
      end
    end
  end

  def run
    puts PROGRAM_COLUMNS.values.reject { |v| UNRANKED_STUDENT_COLUMNS.values.include?(v) }.inspect
    students = match_programs_to_students
    write_csv(students)
  end
end


non_chi_aa_results = ProgramMatchRanker.new(3, "Chi_Res_Re_Imagine24 ApplicantData_Pathways_2.16.16_AA.csv", "Chi_Res_Pathway Program Data_2.16.16.csv", "Chi_Res_Results_AA.csv")
non_chi_aa_results.run
