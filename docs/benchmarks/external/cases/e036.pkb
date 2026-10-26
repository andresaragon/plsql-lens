-- case: e036
-- domain: school grades
-- difficulty: hard
-- note: multi-step term gpa calculation with nested blocks, manual cursor fetch dml, and outer exception handling
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body sch_grade_eval as

  procedure calculate_term_gpa(p_student_id in number, p_term_id in number) is
    cursor c_grades is
      select course_id, credit_hours, grade_points
      from course_enrollments
      where student_id = p_student_id and term_id = p_term_id;
    l_course_id number;
    l_credits   number;
    l_points    number;
    l_current_gpa number;
    l_total_pts   number := 0;
    l_total_cred  number := 0;
  begin
    begin
      select gpa into l_current_gpa from term_records where student_id = p_student_id and term_id = p_term_id; -- clean: PLL004
    exception
      when no_data_found then
        l_current_gpa := 0.0;
    end;

    open c_grades;
    loop
      fetch c_grades into l_course_id, l_credits, l_points;
      exit when c_grades%notfound;
      l_total_pts  := l_total_pts + (l_credits * l_points);
      l_total_cred := l_total_cred + l_credits;
      update student_standing set accumulated_points = accumulated_points + (l_credits * l_points) where student_id = p_student_id; -- expect: PLL005
    end loop;
    close c_grades;

    if l_total_cred > 0 then
      update term_records
      set gpa = round(l_total_pts / l_total_cred, 2)
      where student_id = p_student_id and term_id = p_term_id;
    end if;

    commit; -- clean: PLL003
  exception
    when others then -- clean: PLL001
      logger.log_error(sqlerrm);
      raise;
  end calculate_term_gpa;

  procedure archive_course_evaluations(p_term_id in number) is
    l_passing_score number;
  begin
    l_passing_score := 70.0; -- clean: PLL007
    begin
      update term_evaluations set status = 'ARCHIVED' where term_id = p_term_id;
    exception
      when others then -- expect: PLL001
        null;
    end;

    for r in (select enrollment_id from course_enrollments where term_id = p_term_id) loop
      archive_single_student_history(r.enrollment_id); -- beyond: PLL003 (called procedure commits transaction inside cursor loop)
    end loop;
  end archive_course_evaluations;

end sch_grade_eval;
/
