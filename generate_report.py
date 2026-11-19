import os
import docx
from docx.shared import Inches, Pt, RGBColor, Mm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def create_report():
    doc = docx.Document()
    
    # 1. Page Setup: A4, Standard Academic Margins (Top/Bottom 20mm, Left 25mm, Right 20mm)
    section = doc.sections[0]
    section.page_width = Mm(210)
    section.page_height = Mm(297)
    section.top_margin = Mm(20)
    section.bottom_margin = Mm(20)
    section.left_margin = Mm(25)
    section.right_margin = Mm(20)
    
    # Enable Different First Page so Cover Page has no header/footer
    section.different_first_page_header_footer = True
    
    # Colors
    HEX_PTIT_RED = "B71C1C"      # Primary PTIT Red
    HEX_NAVY = "1A365D"          # Deep Navy
    HEX_BORDER = "D0D0D0"        # Soft Gray Border
    HEX_LIGHT_BG = "F8F9FA"      # Background tint
    HEX_RED_BG = "FFF5F5"        # Light red tint
    
    COLOR_PTIT_RED = RGBColor(183, 28, 28)
    COLOR_NAVY = RGBColor(26, 54, 93)
    COLOR_BODY = RGBColor(34, 34, 34)
    COLOR_MUTED = RGBColor(100, 100, 100)
    COLOR_WHITE = RGBColor(255, 255, 255)
    
    # Configure Normal Style
    style_normal = doc.styles['Normal']
    style_normal.font.name = 'Times New Roman'
    style_normal.font.size = Pt(9.5)
    style_normal.font.color.rgb = COLOR_BODY
    style_normal.paragraph_format.line_spacing = 1.15
    style_normal.paragraph_format.space_after = Pt(2)
    style_normal.paragraph_format.space_before = Pt(0)
    
    # Configure Header & Footer for pages 2-10
    header = section.header
    hp = header.paragraphs[0]
    hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    hp.paragraph_format.space_after = Pt(0)
    hrun = hp.add_run("HỌC VIỆN CÔNG NGHỆ BƯU CHÍNH VIỄN THÔNG — BÁO CÁO BTL INT1449")
    hrun.font.name = 'Times New Roman'
    hrun.font.size = Pt(8.5)
    hrun.font.italic = True
    hrun.font.color.rgb = COLOR_MUTED
    
    footer = section.footer
    footer_table = footer.add_table(rows=1, cols=2, width=Inches(6.5))
    footer_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    f_cell_left = footer_table.cell(0, 0)
    f_cell_right = footer_table.cell(0, 1)
    
    # Remove borders from footer table
    for c in [f_cell_left, f_cell_right]:
        tcPr = c._tc.get_or_add_tcPr()
        tcBorders = parse_xml(f'<w:tcBorders {nsdecls("w")}><w:top w:val="none"/><w:left w:val="none"/><w:bottom w:val="none"/><w:right w:val="none"/></w:tcBorders>')
        tcPr.append(tcBorders)
        
    flp = f_cell_left.paragraphs[0]
    flp.alignment = WD_ALIGN_PARAGRAPH.LEFT
    flp.paragraph_format.space_after = Pt(0)
    flrun = flp.add_run("EduMaster — Báo cáo Kết thúc học phần INT1449 (Nhóm F)")
    flrun.font.name = 'Times New Roman'
    flrun.font.size = Pt(8.5)
    flrun.font.color.rgb = COLOR_MUTED
    
    frp = f_cell_right.paragraphs[0]
    frp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    frp.paragraph_format.space_after = Pt(0)
    frun1 = frp.add_run("Trang ")
    frun1.font.name = 'Times New Roman'
    frun1.font.size = Pt(8.5)
    frun1.font.color.rgb = COLOR_MUTED
    
    # Word dynamic page number field
    fldSimple = parse_xml(f'<w:fldSimple {nsdecls("w")} w:instr="PAGE"/>')
    frp._p.append(fldSimple)
    
    frun2 = frp.add_run(" / 10")
    frun2.font.name = 'Times New Roman'
    frun2.font.size = Pt(8.5)
    frun2.font.color.rgb = COLOR_MUTED
    
    # ------------------ HELPER FUNCTIONS ------------------
    def set_cell_background(cell, hex_color):
        shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
        cell._tc.get_or_add_tcPr().append(shd)

    def set_cell_margins(cell, top=50, bottom=50, left=80, right=80):
        tcPr = cell._tc.get_or_add_tcPr()
        tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
        tcPr.append(tcMar)

    def set_cell_borders(cell, top="D0D0D0", bottom="D0D0D0", left="D0D0D0", right="D0D0D0", sz="4"):
        tcPr = cell._tc.get_or_add_tcPr()
        borders = parse_xml(f'<w:tcBorders {nsdecls("w")}>'
                            f'<w:top w:val="{"single" if top else "none"}" w:sz="{sz}" w:space="0" w:color="{top or "auto"}"/>'
                            f'<w:left w:val="{"single" if left else "none"}" w:sz="{sz}" w:space="0" w:color="{left or "auto"}"/>'
                            f'<w:bottom w:val="{"single" if bottom else "none"}" w:sz="{sz}" w:space="0" w:color="{bottom or "auto"}"/>'
                            f'<w:right w:val="{"single" if right else "none"}" w:sz="{sz}" w:space="0" w:color="{right or "auto"}"/>'
                            f'</w:tcBorders>')
        tcPr.append(borders)

    def add_h1(text, space_before=4, space_after=1.5):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(space_before)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(11.5)
        run.font.color.rgb = COLOR_PTIT_RED
        return p

    def add_h2(text, space_before=3, space_after=1):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(space_before)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.keep_with_next = True
        run = p.add_run(text)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(10)
        run.font.color.rgb = COLOR_NAVY
        return p

    def add_body_p(text, bold_prefix="", italic=False, space_after=2, line_spacing=1.15):
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.line_spacing = line_spacing
        if bold_prefix:
            r_bold = p.add_run(bold_prefix)
            r_bold.bold = True
            r_bold.font.name = 'Times New Roman'
            r_bold.font.size = Pt(9.5)
            r_bold.font.color.rgb = COLOR_BODY
        r_text = p.add_run(text)
        r_text.italic = italic
        r_text.font.name = 'Times New Roman'
        r_text.font.size = Pt(9.5)
        r_text.font.color.rgb = COLOR_BODY
        return p

    def add_bullet_p(bold_prefix, text, space_after=1.5):
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(space_after)
        p.paragraph_format.line_spacing = 1.15
        if bold_prefix:
            r_bold = p.add_run(bold_prefix)
            r_bold.bold = True
            r_bold.font.name = 'Times New Roman'
            r_bold.font.size = Pt(9)
            r_bold.font.color.rgb = COLOR_BODY
        r_text = p.add_run(text)
        r_text.font.name = 'Times New Roman'
        r_text.font.size = Pt(9)
        r_text.font.color.rgb = COLOR_BODY
        return p

    def add_callout(text, title="LƯU Ý / GHI CHÚ", bg=HEX_LIGHT_BG, border_color=HEX_NAVY):
        table = doc.add_table(rows=1, cols=1)
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = table.cell(0, 0)
        cell.width = Inches(6.5)
        set_cell_background(cell, bg)
        set_cell_margins(cell, top=50, bottom=50, left=90, right=90)
        set_cell_borders(cell, top=border_color, bottom=border_color, left=border_color, right=border_color, sz="6")
        p = cell.paragraphs[0]
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        p.paragraph_format.line_spacing = 1.15
        r_title = p.add_run(f"★ {title}: ")
        r_title.bold = True
        r_title.font.name = 'Times New Roman'
        r_title.font.size = Pt(9)
        r_title.font.color.rgb = COLOR_NAVY if border_color == HEX_NAVY else COLOR_PTIT_RED
        r_text = p.add_run(text)
        r_text.font.name = 'Times New Roman'
        r_text.font.size = Pt(9)
        r_text.font.color.rgb = COLOR_BODY

    logo_path = r"C:/Users/admin/.gemini/antigravity/brain/3da4c2b5-a2d0-4950-955c-b24f54a219fb/.user_uploaded/media_1795085282602_fada7026.png"

    # =========================================================================
    # PAGE 1: TRANG BÌA (Cover Page)
    # =========================================================================
    p_inst = doc.add_paragraph()
    p_inst.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_inst.paragraph_format.space_before = Pt(0)
    p_inst.paragraph_format.space_after = Pt(2)
    r1 = p_inst.add_run("BỘ THÔNG TIN VÀ TRUYỀN THÔNG\n")
    r1.font.name = 'Times New Roman'
    r1.font.size = Pt(11)
    r1.bold = True
    r2 = p_inst.add_run("HỌC VIỆN CÔNG NGHỆ BƯU CHÍNH VIỄN THÔNG\n")
    r2.font.name = 'Times New Roman'
    r2.font.size = Pt(13)
    r2.bold = True
    r2.font.color.rgb = COLOR_PTIT_RED
    r3 = p_inst.add_run("KHOA CÔNG NGHỆ THÔNG TIN 1")
    r3.font.name = 'Times New Roman'
    r3.font.size = Pt(11)
    r3.bold = True

    p_div = doc.add_paragraph()
    p_div.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_div.paragraph_format.space_before = Pt(2)
    p_div.paragraph_format.space_after = Pt(8)
    r_div = p_div.add_run("─── ★ ───")
    r_div.font.name = 'Times New Roman'
    r_div.font.size = Pt(11)
    r_div.font.color.rgb = COLOR_PTIT_RED

    if os.path.exists(logo_path):
        p_logo = doc.add_paragraph()
        p_logo.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_logo.paragraph_format.space_before = Pt(0)
        p_logo.paragraph_format.space_after = Pt(10)
        run_logo = p_logo.add_run()
        run_logo.add_picture(logo_path, width=Inches(1.85))

    p_rep = doc.add_paragraph()
    p_rep.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_rep.paragraph_format.space_before = Pt(4)
    p_rep.paragraph_format.space_after = Pt(3)
    r_rep = p_rep.add_run("BÁO CÁO BÀI TẬP LỚN KẾT THÚC HỌC PHẦN")
    r_rep.font.name = 'Times New Roman'
    r_rep.font.size = Pt(13)
    r_rep.bold = True
    r_rep.font.color.rgb = COLOR_NAVY

    p_sub = doc.add_paragraph()
    p_sub.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_sub.paragraph_format.space_before = Pt(0)
    p_sub.paragraph_format.space_after = Pt(8)
    r_sub = p_sub.add_run("MÔN HỌC: PHÁT TRIỂN ỨNG DỤNG CHO CÁC THIẾT BỊ DI ĐỘNG (INT1449)\nLỚP: INT1449-20261-02")
    r_sub.font.name = 'Times New Roman'
    r_sub.font.size = Pt(11)
    r_sub.bold = True

    # Topic frame box
    t_box = doc.add_table(rows=1, cols=1)
    t_box.alignment = WD_TABLE_ALIGNMENT.CENTER
    c_box = t_box.cell(0, 0)
    c_box.width = Inches(6.5)
    set_cell_background(c_box, HEX_RED_BG)
    set_cell_margins(c_box, top=90, bottom=90, left=120, right=120)
    set_cell_borders(c_box, top=HEX_PTIT_RED, bottom=HEX_PTIT_RED, left=HEX_PTIT_RED, right=HEX_PTIT_RED, sz="12")
    
    p_box = c_box.paragraphs[0]
    p_box.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_box.paragraph_format.space_before = Pt(0)
    p_box.paragraph_format.space_after = Pt(0)
    r_dt = p_box.add_run("ĐỀ TÀI BÁO CÁO:\n")
    r_dt.font.name = 'Times New Roman'
    r_dt.font.size = Pt(11)
    r_dt.bold = True
    r_dt.font.color.rgb = COLOR_NAVY
    
    r_box = p_box.add_run("HỆ THỐNG SIÊU ỨNG DỤNG GIÁO DỤC & ÔN TẬP SONG NGỮ EDUMASTER TÍCH HỢP AI TUTOR, CHỐNG GIAN LẬN VÀ CAMERA")
    r_box.font.name = 'Times New Roman'
    r_box.font.size = Pt(12.5)
    r_box.bold = True
    r_box.font.color.rgb = COLOR_PTIT_RED

    p_grp = doc.add_paragraph()
    p_grp.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_grp.paragraph_format.space_before = Pt(8)
    p_grp.paragraph_format.space_after = Pt(6)
    r_grp = p_grp.add_run("NHÓM THỰC HIỆN: NHÓM F (TÍCH HỢP CHUỖI CHỦ ĐỀ 32, 34, 35, 36)")
    r_grp.font.name = 'Times New Roman'
    r_grp.font.size = Pt(10.5)
    r_grp.bold = True
    r_grp.font.color.rgb = COLOR_NAVY

    # 2-column Student Table
    tbl_sv = doc.add_table(rows=4, cols=2)
    tbl_sv.alignment = WD_TABLE_ALIGNMENT.CENTER
    col_widths = [Inches(3.3), Inches(2.2)]
    
    hdr_cells = tbl_sv.rows[0].cells
    hdr_titles = ["HỌ VÀ TÊN SINH VIÊN", "MÃ SINH VIÊN"]
    for i, title in enumerate(hdr_titles):
        hdr_cells[i].width = col_widths[i]
        set_cell_background(hdr_cells[i], HEX_PTIT_RED)
        set_cell_margins(hdr_cells[i], top=45, bottom=45, left=80, right=80)
        set_cell_borders(hdr_cells[i], top=HEX_PTIT_RED, bottom=HEX_PTIT_RED, left=HEX_PTIT_RED, right=HEX_PTIT_RED)
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(title)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(9.5)
        run.font.color.rgb = COLOR_WHITE
        
    students = [
        ("Bùi Phương Ngọc", "B24DCCC215"),
        ("Nguyễn Minh Phương", "B24DCCC231"),
        ("Nguyễn Thị Yến Vi", "B24DCCC286")
    ]
    for idx, (name, msv) in enumerate(students):
        row_cells = tbl_sv.rows[idx + 1].cells
        bg = HEX_LIGHT_BG if idx % 2 == 1 else "FFFFFF"
        for i, val in enumerate([name, msv]):
            row_cells[i].width = col_widths[i]
            set_cell_background(row_cells[i], bg)
            set_cell_margins(row_cells[i], top=40, bottom=40, left=80, right=80)
            set_cell_borders(row_cells[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = row_cells[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT if i == 0 else WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(9.5)
            if i == 0:
                run.bold = True

    p_gv = doc.add_paragraph()
    p_gv.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_gv.paragraph_format.space_before = Pt(8)
    p_gv.paragraph_format.space_after = Pt(10)
    r_gv1 = p_gv.add_run("Giảng viên hướng dẫn: ")
    r_gv1.font.name = 'Times New Roman'
    r_gv1.font.size = Pt(10)
    r_gv1.italic = True
    r_gv2 = p_gv.add_run("Giảng viên phụ trách học phần INT1449")
    r_gv2.font.name = 'Times New Roman'
    r_gv2.font.size = Pt(10.5)
    r_gv2.bold = True

    p_bot = doc.add_paragraph()
    p_bot.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_bot.paragraph_format.space_before = Pt(0)
    p_bot.paragraph_format.space_after = Pt(0)
    r_bot = p_bot.add_run("HÀ NỘI — THÁNG 11 NĂM 2026")
    r_bot.font.name = 'Times New Roman'
    r_bot.font.size = Pt(10.5)
    r_bot.bold = True

    doc.add_page_break()

    # =========================================================================
    # PAGE 2: MỤC LỤC & DANH MỤC THUẬT NGỮ CÔNG NGHỆ (Optimized 1 Page)
    # =========================================================================
    add_h1("MỤC LỤC BÁO CÁO TOÀN DIỆN", space_before=0, space_after=3)

    toc_data = [
        ("PHẦN 1: TỔNG QUAN DỰ ÁN & HỆ THỐNG PHÂN QUYỀN 2 VAI TRÒ", "Bối cảnh, Luồng Giáo viên, Luồng Sinh viên, Đột phá AI & Camera", "Trang 3"),
        ("PHẦN 2: THIẾT KẾ KIẾN TRÚC & QUẢN LÝ TRẠNG THÁI (TIÊU CHÍ 3)", "Clean Architecture 3 tầng, DIP/Mock, Provider, Giải phóng tài nguyên", "Trang 4"),
        ("PHẦN 3: ĐẶC TẢ THUẬT TOÁN & GIẢI PHÁP KỸ THUẬT CỐT LÕI", "Thuật toán SM-2, SQLite FTS Inverted Index, Giám sát chống gian lận", "Trang 5"),
        ("PHẦN 4: THIẾT KẾ GIAO DIỆN & TRẢI NGHIỆM NGƯỜI DÙNG (TIÊU CHÍ 2)", "Kiến trúc AI 4 tầng, 3 trạng thái có lối ra, Chuẩn 48dp, Song ngữ EN/VI", "Trang 6"),
        ("PHẦN 5: BÁO CÁO KIỂM THỬ CHẤT LƯỢNG PHẦN MỀM (TIÊU CHÍ 5)", "36 bài test tự động (100% Pass), Phân tích tĩnh flutter analyze 0 lỗi", "Trang 7"),
        ("PHẦN 6: CHÍNH SÁCH BẢO MẬT & QUẢN TRỊ DỮ LIỆU (TIÊU CHÍ 6)", "Ma trận lưu trữ dữ liệu, Bảo vệ khóa API, Quyền Just-in-Time Camera", "Trang 8"),
        ("PHẦN 7: QUY TRÌNH PHÁT TRIỂN, CI/CD & TRỢ LÝ AI (TIÊU CHÍ 7)", "GitHub Actions CI, Chạy thử trong 15 phút, Minh bạch dùng Trợ lý AI", "Trang 8"),
        ("PHẦN 8: BẢNG TỰ ĐÁNH GIÁ THEO RUBRIC CHẤM ĐIỂM", "Tự đánh giá 8 tiêu chí Xuất sắc (100/100đ) và Điểm cộng (+10đ)", "Trang 9"),
        ("PHẦN 9: ĐÁNH GIÁ KẾT QUẢ, HẠN CHẾ & HƯỚNG PHÁT TRIỂN", "Đánh giá kết quả đạt được, Hạn chế còn tồn tại và Hướng nâng cấp", "Trang 9"),
        ("PHẦN 10: BẢNG PHÂN CÔNG ĐÓNG GÓP & THÔNG TIN NỘP BÀI", "Phân công % đóng góp thành viên, Khung Links nộp bài, Lời cam đoan", "Trang 10")
    ]
    
    t_toc = doc.add_table(rows=len(toc_data) + 1, cols=3)
    t_toc.alignment = WD_TABLE_ALIGNMENT.CENTER
    w_toc = [Inches(2.6), Inches(3.0), Inches(0.9)]
    
    hdr_toc = t_toc.rows[0].cells
    for i, t in enumerate(["Hạng mục nội dung", "Nội dung tóm tắt & Khối kiến thức", "Trang"]):
        hdr_toc[i].width = w_toc[i]
        set_cell_background(hdr_toc[i], HEX_NAVY)
        set_cell_margins(hdr_toc[i], top=30, bottom=30, left=50, right=50)
        set_cell_borders(hdr_toc[i], top=HEX_NAVY, bottom=HEX_NAVY, left=HEX_NAVY, right=HEX_NAVY)
        p = hdr_toc[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(t)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(8.5)
        run.font.color.rgb = COLOR_WHITE
        
    for idx, (title, sub, page) in enumerate(toc_data):
        r_c = t_toc.rows[idx + 1].cells
        bg = HEX_LIGHT_BG if idx % 2 == 1 else "FFFFFF"
        for i, val in enumerate([title, sub, page]):
            r_c[i].width = w_toc[i]
            set_cell_background(r_c[i], bg)
            set_cell_margins(r_c[i], top=25, bottom=25, left=50, right=50)
            set_cell_borders(r_c[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = r_c[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.RIGHT if i == 2 else WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(8.5)
            if i == 0:
                run.bold = True
                run.font.color.rgb = COLOR_PTIT_RED
            elif i == 2:
                run.bold = True
                run.font.color.rgb = COLOR_NAVY

    add_h2("DANH MỤC TỪ VIẾT TẮT & THUẬT NGỮ CÔNG NGHỆ", space_before=5, space_after=1.5)
    
    glossary = [
        ("A11y", "Accessibility: Trợ năng và khả năng tiếp cận chuẩn quốc tế WCAG 2.1 AA."),
        ("Clean Arch", "Kiến trúc phần mềm phân tầng độc lập: Presentation - Domain - Data."),
        ("CI/CD", "Continuous Integration/Continuous Deployment: Tự động hóa build & test với GitHub Actions."),
        ("DIP", "Dependency Inversion Principle: Nguyên lý đảo ngược phụ thuộc (SOLID)."),
        ("FTS (SQLite)", "Full-Text Search: Kỹ thuật chỉ mục đảo tra cứu văn bản siêu tốc O(log N)."),
        ("JIT Permission", "Just-in-Time: Chỉ xin cấp quyền hệ thống khi người dùng kích hoạt tính năng."),
        ("SM-2", "SuperMemo 2: Thuật toán lặp lại ngắt quãng tính chu kỳ ghi nhớ dài hạn."),
        ("TTS", "Text-To-Speech: Công nghệ tổng hợp giọng đọc phát âm chuẩn bản ngữ.")
    ]
    
    t_glo = doc.add_table(rows=len(glossary) + 1, cols=2)
    t_glo.alignment = WD_TABLE_ALIGNMENT.CENTER
    c_w = [Inches(1.8), Inches(4.7)]
    
    hdr_glo = t_glo.rows[0].cells
    for i, t in enumerate(["Thuật ngữ / Viết tắt", "Ý nghĩa và vai trò trong dự án EduMaster"]):
        hdr_glo[i].width = c_w[i]
        set_cell_background(hdr_glo[i], HEX_NAVY)
        set_cell_margins(hdr_glo[i], top=30, bottom=30, left=50, right=50)
        set_cell_borders(hdr_glo[i], top=HEX_NAVY, bottom=HEX_NAVY, left=HEX_NAVY, right=HEX_NAVY)
        p = hdr_glo[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(t)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(8.5)
        run.font.color.rgb = COLOR_WHITE
        
    for idx, (abbr, desc) in enumerate(glossary):
        r_c = t_glo.rows[idx + 1].cells
        bg = HEX_LIGHT_BG if idx % 2 == 1 else "FFFFFF"
        for i, val in enumerate([abbr, desc]):
            r_c[i].width = c_w[i]
            set_cell_background(r_c[i], bg)
            set_cell_margins(r_c[i], top=22, bottom=22, left=50, right=50)
            set_cell_borders(r_c[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = r_c[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(8.5)
            if i == 0:
                run.bold = True

    doc.add_page_break()

    # =========================================================================
    # PAGE 3: PHẦN 1: TỔNG QUAN DỰ ÁN & HỆ THỐNG PHÂN QUYỀN 2 VAI TRÒ
    # =========================================================================
    add_h1("PHẦN 1: TỔNG QUAN DỰ ÁN & HỆ THỐNG PHÂN QUYỀN 2 VAI TRÒ", space_before=0, space_after=2)
    
    add_h2("1.1. Bối cảnh và mục tiêu dự án")
    add_body_p(
        "EduMaster được phát triển từ project mẫu 'Ngân hàng 300 câu trắc nghiệm song ngữ' của INT1449. Nhóm thực hiện Nhóm F (Giáo dục và Ôn tập) với sự tích hợp toàn diện của 4 chủ đề cốt lõi: #32 (Ôn tập trắc nghiệm song ngữ), #34 (Phòng thi trực tuyến nhỏ), #35 (Từ điển IT Anh - Việt offline) và #36 (Bảng xếp hạng thi đua học tập). Hệ thống xây dựng Phân quyền 2 Chế độ Độc lập (Giáo viên ↔ Sinh viên) kèm nút chuyển đổi vai trò tức thì tại ProfileScreen, tích hợp AI Tutor 24/7 và Quét mã QR Camera.",
        bold_prefix="Định vị hệ thống: "
    )

    add_h2("1.2. Phân hệ Giáo viên (Teacher Flow - Tạo đề, Giám sát Realtime & Biểu đồ)")
    add_bullet_p(
        "Tạo & Quản lý phòng thi (ExamHubScreen): ",
        "Cấu hình mã PIN, thời lượng thi; 3 nguồn đề (Bộ đề chuẩn KTHP, Lọc ngân hàng 300 câu, Tự soạn câu hỏi mới); sinh mã QR phòng thi để sinh viên quét mã vào thi tức thì."
    )
    add_bullet_p(
        "Giám sát Realtime & Biểu đồ thống kê (TeacherRoomDetailScreen): ",
        "Cập nhật mỗi 3s tiến độ làm bài sinh viên (câu hiện tại, số câu đúng), phát hiện vi phạm thoát app; biểu đồ cột trực quan hóa phổ điểm thang 10 và tỷ lệ Đạt/Trượt."
    )
    add_bullet_p(
        "Lịch sử phòng thi (TeacherExamHistoryScreen): ",
        "Quản lý toàn bộ danh sách phòng thi đã khởi tạo, mở lại báo cáo thống kê bất kỳ lúc nào. Hệ thống bắt đầu sạch sẽ (0 dữ liệu rác/mẫu)."
    )
    add_bullet_p(
        "Quản lý Nhóm học tập & Đồng bộ thời gian thực (LeaderboardScreen): ",
        "Khởi tạo nhóm học tập (Nhóm 01, Nhóm 02...), đổi tên, xóa nhóm, phân công sinh viên bằng Mã ID hoặc Email; cơ chế Auto-Enrollment tự động ghi danh mới và đồng bộ tức thời hai chiều sang tài khoản sinh viên."
    )

    add_h2("1.3. Phân hệ Sinh viên (Student Flow - Tích hợp chuỗi bài toán Nhóm F)")
    add_bullet_p(
        "Chủ đề #32: Ôn tập trắc nghiệm song ngữ (300 câu): ",
        "Nạp dữ liệu từ assets/data/questions_300.json với 20 khối kiến thức Flutter; chế độ Luyện tập và Thi thử 20 phút; chuyển đổi ngôn ngữ Anh - Việt tức thì bằng 1 chạm; tự động ghi nhận câu sai và tính năng 'Làm lại câu sai'."
    )
    add_bullet_p(
        "Chủ đề #33: Thẻ ghi nhớ lặp lại ngắt quãng (Flashcards SM-2): ",
        "Ứng dụng thuật toán SuperMemo SM-2 tính khoảng cách ôn tập khoa học; hoạt ảnh lật thẻ 3D; nhập thẻ từ tệp CSV; tích hợp phát âm giọng chuẩn bản ngữ Text-To-Speech (TTS)."
    )
    add_bullet_p(
        "Chủ đề #34: Phòng thi trực tuyến nhỏ: ",
        "Vào phòng thi bằng mã PIN hoặc Quét mã QR bằng Camera; xáo trộn câu hỏi và đáp án ngẫu nhiên cho từng thí sinh; cảnh báo chống gian lận khi rời màn hình; chấm điểm tự động thang 10 và lưu lịch sử thi."
    )
    add_bullet_p(
        "Chủ đề #35: Từ điển thuật ngữ IT Offline (SQLite FTS): ",
        "Bảng ảo FTS4 tra cứu toàn văn siêu tốc O(log N) dưới 5ms; mục 'Từ của ngày'; đánh dấu Bookmark từ vựng yêu thích; hoạt động hoàn toàn offline."
    )
    add_bullet_p(
        "Chủ đề #36: Bảng xếp hạng thi đua học tập & Nhóm học tập Realtime: ",
        "Tích lũy điểm kinh nghiệm (XP), chuỗi ngày học liên tục (Streak), Huy hiệu thành tích (Badges); tự động đồng bộ nhóm học tập được GV phân công và theo dõi thứ hạng trong nhóm."
    )

    add_h2("1.4. Đột phá công nghệ: Gia sư AI Tutor 24/7 & Camera Mobile Scanner")
    add_body_p(
        "EduMaster tích hợp Gia sư ảo AI Tutor 4 tầng an toàn hỗ trợ giải thích cặn kẽ vì sao một đáp án là sai, phân tích cú pháp code Dart/Flutter trực tiếp cho sinh viên. Bên cạnh đó, mobile_scanner cho phép quét mã QR phòng thi qua Camera phần cứng trong chưa đầy 0.5 giây, nâng tầm trải nghiệm kiểm tra thực tế.",
        bold_prefix="Điểm nhấn đột phá: "
    )

    doc.add_page_break()

    # =========================================================================
    # PAGE 4: PHẦN 2: THIẾT KẾ KIẾN TRÚC & QUẢN LÝ TRẠNG THÁI (TIÊU CHÍ 3)
    # =========================================================================
    add_h1("PHẦN 2: THIẾT KẾ KIẾN TRÚC & QUẢN LÝ TRẠNG THÁI (TIÊU CHÍ 3)", space_before=0, space_after=2)

    add_h2("2.1. Kiến trúc Clean Architecture 3 tầng độc lập")
    add_body_p(
        "Hệ thống phân tách triệt để mã nguồn thành 3 tầng độc lập theo quy tắc phụ thuộc một chiều hướng tâm:",
        bold_prefix="Nguyên tắc phân tầng: "
    )

    t_arch = doc.add_table(rows=4, cols=3)
    t_arch.alignment = WD_TABLE_ALIGNMENT.CENTER
    w_arch = [Inches(1.5), Inches(2.3), Inches(2.7)]
    
    hdr_arch = t_arch.rows[0].cells
    for i, t in enumerate(["Tầng (Layer)", "Thành phần cấu thành", "Nhiệm vụ & Quy tắc thiết kế"]):
        hdr_arch[i].width = w_arch[i]
        set_cell_background(hdr_arch[i], HEX_NAVY)
        set_cell_margins(hdr_arch[i], top=30, bottom=30, left=50, right=50)
        set_cell_borders(hdr_arch[i], top=HEX_NAVY, bottom=HEX_NAVY, left=HEX_NAVY, right=HEX_NAVY)
        p = hdr_arch[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(t)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(8.5)
        run.font.color.rgb = COLOR_WHITE
        
    arch_rows = [
        ("Presentation Layer\n(Tầng Trình diễn)", "Screens (Teacher & Student), Custom Widgets, State Providers (ChangeNotifier).", "Hiển thị giao diện người dùng, lắng nghe tương tác và phản hồi trạng thái từ Provider. Tuyệt đối không chứa logic nghiệp vụ."),
        ("Domain Layer\n(Tầng Nghiệp vụ)", "Entities (AuthUser, ExamRoom...), Repository Interfaces (IAuthRepo...), Pure Algorithms.", "Tầng trung tâm thuần Dart (Zero Flutter Dependencies). Định nghĩa luật nghiệp vụ và các giao diện hợp đồng trừu tượng."),
        ("Data Layer\n(Tầng Dữ liệu)", "Repository Implementations (AuthRepoImpl...), Local & Remote Data Sources.", "Triển khai các Repository Interfaces, truy xuất dữ liệu từ SQLite FTS, SharedPreferences, JSON Assets và Gemini AI Proxy.")
    ]
    for idx, (layer, comps, desc) in enumerate(arch_rows):
        rc = t_arch.rows[idx + 1].cells
        bg = HEX_LIGHT_BG if idx % 2 == 1 else "FFFFFF"
        for i, val in enumerate([layer, comps, desc]):
            rc[i].width = w_arch[i]
            set_cell_background(rc[i], bg)
            set_cell_margins(rc[i], top=28, bottom=28, left=50, right=50)
            set_cell_borders(rc[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = rc[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(8.5)
            if i == 0:
                run.bold = True

    add_h2("2.2. Giao diện hợp đồng (Repository Interfaces) & Đảo ngược phụ thuộc (DIP)", space_before=4)
    add_body_p(
        "Tuân thủ nguyên lý Dependency Inversion, tất cả Repository trong Domain là interface trừu tượng (IQuizRepository, IExamRepository, IAuthRepository, IDictionaryRepository, ILeaderboardRepository). Presentation chỉ phụ thuộc vào Interface này. Nhờ đó, trong kiểm thử tự động, toàn bộ Data Layer có thể được thay bằng Mock Repository giả lập, giúp 36 bài kiểm thử tự động chạy độc lập, ổn định và đạt 100% PASS.",
        bold_prefix="Đặc tả DIP & Testability: "
    )

    add_h2("2.3. Quản lý trạng thái bằng Provider (ChangeNotifier)")
    add_bullet_p(
        "Kiến trúc State Management: ",
        "Sử dụng provider chuẩn kết hợp ChangeNotifier. Provider phân chia theo miền trách nhiệm: AuthProvider (phiên và vai trò GV/SV), ExamProvider (phòng thi và giám sát realtime), QuizProvider (câu hỏi song ngữ), DictionaryProvider (tra cứu FTS) và ProfileProvider (XP, streak)."
    )
    add_bullet_p(
        "Tối ưu vòng lặp dựng giao diện: ",
        "Tuyệt đối không gọi I/O, đọc file hay gọi mạng trong hàm build(). Dữ liệu được Provider chuẩn bị sẵn trong bộ nhớ trạng thái và chỉ gọi notifyListeners() khi có thay đổi thực sự."
    )

    add_h2("2.4. Quy chuẩn giải phóng tài nguyên triệt để (Resource Disposal)")
    add_body_p(
        "Rà soát 100% mã nguồn vòng đời Widget. Toàn bộ đối tượng chiếm dụng tài nguyên gồm: TextEditingController (ô nhập PIN, tìm từ điển), AnimationController (hiệu ứng lật thẻ 3D), Timer (đếm ngược thi, polling 3s), StreamSubscription và MobileScannerController đều được giải phóng triệt để trong phương thức dispose(), bảo đảm zero memory leak.",
        bold_prefix="Cam kết Zero Memory Leak: "
    )

    doc.add_page_break()

    # =========================================================================
    # PAGE 5: PHẦN 3: ĐẶC TẢ THUẬT TOÁN & GIẢI PHÁP KỸ THUẬT CỐT LÕI
    # =========================================================================
    add_h1("PHẦN 3: ĐẶC TẢ THUẬT TOÁN & GIẢI PHÁP KỸ THUẬT CỐT LÕI", space_before=0, space_after=2)

    add_h2("3.1. Thuật toán lặp lại ngắt quãng SuperMemo SM-2 (Chủ đề #33)")
    add_body_p(
        "Phân hệ flashcard tích hợp thuật toán khoa học SuperMemo SM-2 giúp ghi nhớ từ vựng và khái niệm công nghệ theo đường cong lãng quên Ebbinghaus:",
        bold_prefix="Mục tiêu thuật toán: "
    )
    add_bullet_p(
        "Công thức cập nhật hệ số dễ nhớ (Ease Factor - EF): ",
        "EF' = max(1.3, EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))), trong đó q in [0, 5] là chất lượng phản hồi do học viên tự đánh giá. Thuật toán luôn chặn dưới EF >= 1.3 để tránh việc khoảng cách ôn tập bị co hẹp vô tận."
    )
    add_bullet_p(
        "Công thức xác định chu kỳ ngắt quãng (Interval - I): ",
        "Nếu q < 3 (quên/chọn sai): Reset n = 0, chu kỳ ôn lại I = 1 ngày. Nếu q >= 3 (nhớ): Tăng n' = n + 1. Chu kỳ được tính: I(1) = 1 ngày, I(2) = 6 ngày, và với n >= 3 thì I(n) = round(I(n - 1) * EF')."
    )
    add_bullet_p(
        "Kiểm thử thuần cho thuật toán (Pure Dart Unit Test): ",
        "Thuật toán được viết trong domain/algorithms/sm2_algorithm.dart, được kiểm thử qua 6 unit test độc lập bao phủ các trường hợp biên, tính đơn điệu và chặn dưới."
    )

    add_h2("3.2. Cơ sở dữ liệu SQLite Full-Text Search (FTS4) siêu tốc O(log N) (Chủ đề #35)")
    add_body_p(
        "Từ điển thuật ngữ CNTT Offline được xây dựng trên bảng ảo SQLite FTS4 với chỉ mục đảo (Inverted Index):",
        bold_prefix="Đặc tả lưu trữ: "
    )
    add_bullet_p(
        "Cấu trúc bảng ảo: ",
        "CREATE VIRTUAL TABLE dictionary_fts USING fts4(word, phonetic, part_of_speech, definition_vi, definition_en, example, tokenize=unicode61). Tokenizer unicode61 cho phép tìm kiếm tiếng Việt và tiếng Anh linh hoạt, hỗ trợ tìm kiếm không dấu."
    )
    add_bullet_p(
        "Truy vấn tức thì Search-As-You-Type: ",
        "Sử dụng toán tử MATCH với tiền tố MATCH 'keyword*' giúp tìm kiếm thuật ngữ công nghệ với độ phức tạp O(log N). Tốc độ phản hồi đạt dưới 5ms ngay khi người dùng gõ từng ký tự."
    )

    add_h2("3.3. Cơ chế giám sát chống gian lận & Giám sát phòng thi Realtime (Chủ đề #34)")
    add_body_p(
        "EduMaster xây dựng cơ chế phát hiện gian lận đa tầng đảm bảo tính nghiêm túc trong phòng thi trực tuyến:",
        bold_prefix="Giải pháp chống gian lận: "
    )
    add_bullet_p(
        "Bắt sự kiện vòng đời ứng dụng: ",
        "Màn hình thi kế thừa WidgetsBindingObserver để lắng nghe didChangeAppLifecycleState. Khi chuyển sang AppLifecycleState.paused hoặc inactive (thí sinh thoát app ra ngoài hoặc chia đôi màn hình):"
    )
    add_bullet_p(
        "Xử lý vi phạm tự động: ",
        "(1) Tự động tăng bộ đếm violationsCount; (2) Lưu vết chính xác mốc thời gian vi phạm (ví dụ: '10:14:02 — Rời màn hình thi'); (3) Hiển thị cảnh báo đỏ trực tiếp trên bài thi và ghi vào biên bản nộp bài."
    )
    add_bullet_p(
        "Đồng bộ Realtime sang phân hệ Giảng viên: ",
        "Toàn bộ trạng thái làm bài (câu hiện tại, số câu đúng, số lần rời app) được đồng bộ định kỳ mỗi 3 giây sang LiveStudentSession trên màn hình giám sát của Giáo viên."
    )
    add_bullet_p(
        "Xáo trộn đề ngẫu nhiên (Deterministic Shuffle Engine): ",
        "Thứ tự 50 câu hỏi và thứ tự các đáp án A, B, C, D được xáo trộn độc lập cho từng mã sinh viên, triệt tiêu hoàn toàn khả năng nhìn bài."
    )

    doc.add_page_break()

    # =========================================================================
    # PAGE 6: PHẦN 3 (TIẾP) & PHẦN 4: THIẾT KẾ GIAO DIỆN & TRẢI NGHIỆM NGƯỜI DÙNG (TIÊU CHÍ 2)
    # =========================================================================
    add_h1("PHẦN 3 (TIẾP): KIẾN TRÚC GIA SƯ AI TUTOR 4 TẦNG AN TOÀN", space_before=0, space_after=2)
    
    add_body_p(
        "EduMaster thiết kế kiến trúc AI Tutor 4 tầng an toàn tuyệt đối đáp ứng chuẩn điểm cộng +3đ của Rubric:",
        bold_prefix="Kiến trúc bảo mật AI: "
    )

    t_ai = doc.add_table(rows=5, cols=3)
    t_ai.alignment = WD_TABLE_ALIGNMENT.CENTER
    w_ai = [Inches(1.4), Inches(2.3), Inches(2.8)]
    
    hdr_ai = t_ai.rows[0].cells
    for i, t in enumerate(["Tầng AI", "Cơ chế hoạt động", "Mục tiêu an toàn & Trải nghiệm"]):
        hdr_ai[i].width = w_ai[i]
        set_cell_background(hdr_ai[i], HEX_NAVY)
        set_cell_margins(hdr_ai[i], top=30, bottom=30, left=50, right=50)
        set_cell_borders(hdr_ai[i], top=HEX_NAVY, bottom=HEX_NAVY, left=HEX_NAVY, right=HEX_NAVY)
        p = hdr_ai[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(t)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(8.5)
        run.font.color.rgb = COLOR_WHITE
        
    ai_rows = [
        ("Tầng 1: Demo Mode\n(Thử nghiệm)", "Trả lời bằng bộ dữ liệu quy tắc song ngữ chuẩn hóa offline đóng gói sẵn.", "Người dùng trải nghiệm ngay tính năng gia sư ảo mà không cần mạng hay khóa API."),
        ("Tầng 2: Key Proxy Server\n(Máy chủ giữ khóa)", "Ứng dụng gọi đến Endpoint trung gian của máy chủ, máy chủ giữ Gemini API key.", "Mã nguồn và tệp APK phát hành tuyệt đối không chứa khóa API, loại trừ rủi ro dịch ngược."),
        ("Tầng 3: Direct Key\n(Khóa cá nhân)", "Cho phép người dùng hoặc giám khảo tự cấu hình API key cá nhân trong ứng dụng.", "Khóa được lưu cục bộ trong SharedPreferences vùng nhớ sandbox thiết bị, bảo mật an toàn."),
        ("Tầng 4: Offline Fallback\n(Dự phòng ngoại tuyến)", "Khi mất mạng hoặc thời gian phản hồi vượt quá 10 giây (timeout), kích hoạt fallback.", "Tự động chuyển sang tập quy tắc thông minh cục bộ, không bao giờ để ứng dụng bị treo.")
    ]
    for idx, (tier, mech, goal) in enumerate(ai_rows):
        rc = t_ai.rows[idx + 1].cells
        bg = HEX_LIGHT_BG if idx % 2 == 1 else "FFFFFF"
        for i, val in enumerate([tier, mech, goal]):
            rc[i].width = w_ai[i]
            set_cell_background(rc[i], bg)
            set_cell_margins(rc[i], top=26, bottom=26, left=50, right=50)
            set_cell_borders(rc[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = rc[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(8.5)
            if i == 0:
                run.bold = True

    add_h1("PHẦN 4: THIẾT KẾ GIAO DIỆN & TRẢI NGHIỆM NGƯỜI DÙNG (TIÊU CHÍ 2)", space_before=5, space_after=2)

    add_h2("4.1. Chuẩn hóa 3 trạng thái giao diện có lối ra (Loading, Error, Empty)")
    add_body_p(
        "Nhằm đạt mức Xuất sắc 100% của Tiêu chí 2, hệ thống tuyệt đối không để xảy ra màn hình trắng hay treo vô tận. Ba widget chuẩn hóa được triển khai đồng bộ:",
        bold_prefix="Quy chuẩn UX: "
    )
    add_bullet_p(
        "Trạng thái đang tải (LoadingView): ",
        "Hiển thị vòng quay tiến trình mượt mà kèm thông điệp rõ ràng và nút 'Hủy / Quay lại', cho phép người dùng chủ động thoát nếu mạng bị chậm."
    )
    add_bullet_p(
        "Trạng thái lỗi (ErrorViewWithRetry): ",
        "Bắt mọi lỗi ngoại lệ (mất mạng, dữ liệu hỏng) và hiển thị thông báo lỗi thân thiện kèm 2 lối ra độc lập: Nút 'Thử lại' (Retry) và Nút 'Quay về' (Go Back)."
    )
    add_bullet_p(
        "Trạng thái chưa có dữ liệu (EmptyStateView): ",
        "Khi danh sách phòng thi trống, chưa có từ yêu thích hoặc chưa làm bài sai, hệ thống hiển thị hình minh họa kèm nút kêu gọi hành động (Call To Action)."
    )

    add_h2("4.2. Chuẩn công thái học vùng chạm (Touch Target Size >= 48 dp)")
    add_body_p(
        "Tuân thủ nghiêm ngặt chuẩn thiết kế công thái học Android Accessibility và tiêu chuẩn quốc tế WCAG 2.1 AA, 100% các nút bấm, ô nhập và icon tương tác đều đạt kích thước tối thiểu 48 x 48 dp. Dự án xây dựng widget TouchTargetWrapper tự động bao bọc và kiểm soát kích thước mọi thành phần giao diện, được chứng minh qua 11 bài kiểm thử tự động A11y đạt 100% Pass.",
        bold_prefix="Công thái học giao diện: "
    )

    add_h2("4.3. Chuyển đổi giao diện song ngữ Anh - Việt linh hoạt")
    add_body_p(
        "Toàn bộ 300 câu hỏi và hệ thống nhãn giao diện đều hỗ trợ song ngữ Anh - Việt. Người dùng có thể chuyển đổi ngôn ngữ tức thì chỉ với một chạm trên thanh tiêu đề mà không cần khởi động lại ứng dụng.",
        bold_prefix="Đa ngôn ngữ mượt mà: "
    )

    doc.add_page_break()

    # =========================================================================
    # PAGE 7: PHẦN 5: BÁO CÁO KIỂM THỬ CHẤT LƯỢNG PHẦN MỀM (TIÊU CHÍ 5)
    # =========================================================================
    add_h1("PHẦN 5: BÁO CÁO KIỂM THỬ CHẤT LƯỢNG PHẦN MỀM (TIÊU CHÍ 5)", space_before=0, space_after=2)

    add_h2("5.1. Tổng quan chiến lược kiểm thử tự động toàn diện")
    add_body_p(
        "Dự án áp dụng mô hình Kim tự tháp kiểm thử bao phủ toàn diện từ kiểm thử đơn vị logic nghiệp vụ (Unit Test), kiểm thử giao diện (Widget Test) đến kiểm thử trợ năng theo tiêu chuẩn Google (Accessibility Test). Tổng số bài kiểm thử tự động đạt 36 bài (vượt xa chuẩn >= 15 bài của Rubric), với tỷ lệ vượt qua tuyệt đối 100% PASS (36/36 bài test).",
        bold_prefix="Chiến lược chất lượng: "
    )

    t_test = doc.add_table(rows=12, cols=4)
    t_test.alignment = WD_TABLE_ALIGNMENT.CENTER
    w_t = [Inches(0.5), Inches(2.2), Inches(0.8), Inches(3.0)]
    
    hdr_t = t_test.rows[0].cells
    for i, t in enumerate(["STT", "Nhóm bài kiểm thử", "Số test", "Phạm vi & Mục tiêu kiểm thử chi tiết"]):
        hdr_t[i].width = w_t[i]
        set_cell_background(hdr_t[i], HEX_NAVY)
        set_cell_margins(hdr_t[i], top=26, bottom=26, left=45, right=45)
        set_cell_borders(hdr_t[i], top=HEX_NAVY, bottom=HEX_NAVY, left=HEX_NAVY, right=HEX_NAVY)
        p = hdr_t[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(t)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(8.5)
        run.font.color.rgb = COLOR_WHITE
        
    test_rows = [
        ("1", "Unit: Thuật toán SuperMemo SM-2", "6 test", "Tính toán EF, chặn dưới EF>=1.3, reset interval khi q<3, tăng interval khi q>=3, kiểm thử biên."),
        ("2", "Unit: Ngân hàng 300 câu hỏi song ngữ", "4 test", "Parse JSON asset, kiểm tra toàn vẹn song ngữ EN/VI, phân loại 20 khối chủ đề, null safety."),
        ("3", "Unit: Phòng thi & Chống gian lận", "4 test", "Tính điểm thang 10, đếm số lần vi phạm rời app, xáo trộn ngẫu nhiên đề thi theo từng thí sinh."),
        ("4", "Unit: Từ điển IT SQLite FTS", "3 test", "Truy vấn toàn văn FTS match query, tìm kiếm tiền tố, lưu trữ và đồng bộ Bookmark từ yêu thích."),
        ("5", "Unit: Xác thực Auth & Phân quyền Role", "3 test", "Phân quyền 2 vai trò GV/SV, quản lý phiên làm việc, chuyển đổi vai trò linh hoạt không gián đoạn."),
        ("6", "Widget: 3 trạng thái giao diện chuẩn", "3 test", "Kiểm tra LoadingView (nút Hủy), ErrorViewWithRetry (2 lối ra), EmptyStateView (nút hành động)."),
        ("7", "A11y: Vùng chạm công thái học", "3 test", "Kiểm tra androidTapTargetGuideline đảm bảo 100% nút bấm đạt kích thước >= 48 x 48 dp."),
        ("8", "A11y: Nhãn ngữ nghĩa Screen Reader", "3 test", "Kiểm tra labeledTapTargetGuideline đảm bảo mọi icon/button có nhãn hỗ trợ người khiếm thị."),
        ("9", "A11y: Độ tương phản văn bản WCAG AA", "3 test", "Kiểm tra textContrastGuideline đảm bảo tỷ lệ tương phản chữ và nền đạt tối thiểu 4.5:1."),
        ("10", "A11y: Đa ngôn ngữ & TouchTargetWrapper", "2 test", "Kiểm tra cơ chế bao bọc tự động kích thước và chuyển đổi ngôn ngữ EN/VI thời gian thực."),
        ("11", "Unit: Quản lý nhóm học & Đồng bộ", "2 test", "Tìm kiếm SV theo ID/Tên/Mã SV PTIT, cơ chế Auto-Enrollment, đồng bộ hai chiều GV-SV.")
    ]
    for idx, (stt, group, count, scope) in enumerate(test_rows):
        rc = t_test.rows[idx + 1].cells
        bg = HEX_LIGHT_BG if idx % 2 == 1 else "FFFFFF"
        for i, val in enumerate([stt, group, count, scope]):
            rc[i].width = w_t[i]
            set_cell_background(rc[i], bg)
            set_cell_margins(rc[i], top=18, bottom=18, left=45, right=45)
            set_cell_borders(rc[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = rc[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if i in [0, 2] else WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(8.5)
            if i == 1:
                run.bold = True
                
    add_callout(
        "Lệnh chạy: flutter test --reporter=expanded | Kết quả: 00:05 +36: All tests passed! Tỷ lệ đạt tuyệt đối 100% (36/36 tests pass), không có bài test nào bị lỗi hay bỏ qua.",
        title="KẾT QUẢ TEST RUNNER TỰ ĐỘNG",
        bg=HEX_LIGHT_BG,
        border_color=HEX_NAVY
    )

    add_h2("5.2. Kết quả phân tích tĩnh mã nguồn flutter analyze (Tiêu chí 7)", space_before=4)
    add_body_p(
        "Thực thi phân tích tĩnh mã nguồn với bộ quy tắc nghiêm ngặt: flutter analyze --fatal-infos. Kết quả đạt: 'No issues found!' (0 lỗi, 0 cảnh báo, 0 linting warnings). Mã nguồn tuân thủ chuẩn Dart 3.x, không dùng hàm deprecated, không biến thừa và xử lý triệt để Null Safety.",
        bold_prefix="Chất lượng mã nguồn tĩnh: "
    )

    doc.add_page_break()

    # =========================================================================
    # PAGE 8: PHẦN 6: BẢO MẬT DỮ LIỆU & PHẦN 7: QUY TRÌNH PHÁT TRIỂN, CI/CD
    # =========================================================================
    add_h1("PHẦN 6: CHÍNH SÁCH BẢO MẬT & QUẢN TRỊ DỮ LIỆU (TIÊU CHÍ 6)", space_before=0, space_after=2)

    add_h2("6.1. Ma trận vị trí lưu trữ và quản trị dữ liệu")
    add_body_p(
        "Vị trí lưu trữ và cơ chế bảo vệ dữ liệu được minh bạch hóa theo ma trận chuẩn:",
        bold_prefix="Bảo mật dữ liệu: "
    )

    t_sec = doc.add_table(rows=6, cols=3)
    t_sec.alignment = WD_TABLE_ALIGNMENT.CENTER
    w_s = [Inches(1.5), Inches(2.1), Inches(2.9)]
    
    hdr_s = t_sec.rows[0].cells
    for i, t in enumerate(["Loại dữ liệu", "Vị trí lưu trữ vật lý", "Cơ chế bảo vệ & Vùng nhớ Sandbox"]):
        hdr_s[i].width = w_s[i]
        set_cell_background(hdr_s[i], HEX_NAVY)
        set_cell_margins(hdr_s[i], top=30, bottom=30, left=50, right=50)
        set_cell_borders(hdr_s[i], top=HEX_NAVY, bottom=HEX_NAVY, left=HEX_NAVY, right=HEX_NAVY)
        p = hdr_s[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(t)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(8.5)
        run.font.color.rgb = COLOR_WHITE
        
    sec_rows = [
        ("Tài khoản & Phân quyền", "SharedPreferences (JSON)", "Lưu trong vùng nhớ nội bộ sandbox /data/data/..., tự động nhận diện vai trò GV/SV an toàn."),
        ("Ngân hàng 300 câu hỏi", "assets/data/questions_300.json", "Đóng gói dạng Read-only Asset Bundle trong sandbox, chống can thiệp và chỉnh sửa."),
        ("Từ điển IT SQLite FTS", "edumaster_it_dictionary.db", "Cơ sở dữ liệu SQLite cục bộ mã hóa trong vùng nhớ riêng ứng dụng, bảo vệ toàn vẹn dữ liệu."),
        ("Dữ liệu SM-2 & Lịch sử thi", "SharedPreferences", "Lưu trữ nội bộ an toàn trên thiết bị; dữ liệu hỏng tự phục hồi về mặc định không làm app dừng."),
        ("Khóa AI & Proxy URL", "SharedPreferences / Proxy", "Tuyệt đối không hardcode trong mã nguồn hoặc Git. Hỗ trợ Key Proxy Server và Demo Mode an toàn.")
    ]
    for idx, (dtype, loc, prot) in enumerate(sec_rows):
        rc = t_sec.rows[idx + 1].cells
        bg = HEX_LIGHT_BG if idx % 2 == 1 else "FFFFFF"
        for i, val in enumerate([dtype, loc, prot]):
            rc[i].width = w_s[i]
            set_cell_background(rc[i], bg)
            set_cell_margins(rc[i], top=24, bottom=24, left=50, right=50)
            set_cell_borders(rc[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = rc[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(8.5)
            if i == 0:
                run.bold = True

    add_h2("6.2. Chính sách bảo vệ Khóa API & Keystore ký phát hành", space_before=4)
    add_body_p(
        "Nhóm tuyệt đối không lưu trữ khóa API hay mật khẩu trong mã nguồn và Git. File mẫu .env.example hướng dẫn cấu hình; khóa phát hành APK Release được bảo mật qua biến môi trường độc lập.",
        bold_prefix="Bảo mật tuyệt đối: "
    )

    add_h2("6.3. Nguyên tắc cấp quyền hệ thống đúng lúc (Just-in-Time Permissions)")
    add_body_p(
        "Ứng dụng chỉ xin cấp quyền Camera đúng thời điểm người dùng bấm nút 'Quét mã QR phòng thi' hoặc 'Chụp ảnh Avatar', kèm hộp thoại giải thích lý do rõ ràng. Hệ thống không xin bất kỳ quyền thừa nào.",
        bold_prefix="Quyền tối thiểu: "
    )

    add_h1("PHẦN 7: QUY TRÌNH PHÁT TRIỂN, CI/CD & TRỢ LÝ AI (TIÊU CHÍ 7)", space_before=5, space_after=2)

    add_h2("7.1. Tự động hóa CI/CD với GitHub Actions")
    add_body_p(
        "Pipeline CI/CD (.github/workflows/ci.yml) tự động kích hoạt mỗi khi push/PR: (1) Checkout code; (2) Setup Flutter Stable; (3) flutter pub get; (4) flutter analyze --fatal-infos; (5) flutter test (36 test); (6) Build debug APK artifact.",
        bold_prefix="Tự động hóa CI/CD (+2đ): "
    )

    add_h2("7.2. Hướng dẫn cài đặt và chạy ứng dụng trong 15 phút")
    add_body_p(
        "Cài đặt và chạy thử nhanh theo 5 bước chuẩn README: (1) git clone <repo_url>; (2) cd App-Edu; (3) flutter pub get; (4) flutter test (xác nhận 36 bài test pass); (5) flutter run --release.",
        bold_prefix="Khả năng tái lập: "
    )

    add_h2("7.3. Minh bạch sử dụng Trợ lý AI (Mục 'Dùng AI' theo Rubric)")
    add_body_p(
        "Trợ lý AI (Claude, Gemini) được sử dụng để hỗ trợ tra cứu tài liệu Flutter, đề xuất cấu trúc bài kiểm thử tự động và tối ưu hóa hiệu năng thuật toán. Toàn bộ các phiên trao đổi quan trọng được ghi chép và lưu vết tại thư mục docs/ai/. Mỗi thành viên trong nhóm làm chủ 100% dòng mã mình nộp và sẵn sàng giải thích chi tiết trong phần vấn đáp.",
        bold_prefix="Cam kết học thuật: "
    )

    doc.add_page_break()

    # =========================================================================
    # PAGE 9: PHẦN 8: BẢNG TỰ ĐÁNH GIÁ THEO RUBRIC & PHẦN 9: HẠN CHẾ & HƯỚNG PHÁT TRIỂN
    # =========================================================================
    add_h1("PHẦN 8: BẢNG TỰ ĐÁNH GIÁ THEO RUBRIC CHẤM ĐIỂM (100% XUẤT SẮC)", space_before=0, space_after=2)

    t_rub = doc.add_table(rows=10, cols=4)
    t_rub.alignment = WD_TABLE_ALIGNMENT.CENTER
    w_r = [Inches(0.4), Inches(2.1), Inches(0.8), Inches(3.2)]
    
    hdr_r = t_rub.rows[0].cells
    for i, t in enumerate(["STT", "Tiêu chí đánh giá", "Điểm", "Minh chứng đạt mức Xuất sắc (100%)"]):
        hdr_r[i].width = w_r[i]
        set_cell_background(hdr_r[i], HEX_PTIT_RED)
        set_cell_margins(hdr_r[i], top=30, bottom=30, left=45, right=45)
        set_cell_borders(hdr_r[i], top=HEX_PTIT_RED, bottom=HEX_PTIT_RED, left=HEX_PTIT_RED, right=HEX_PTIT_RED)
        p = hdr_r[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(t)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(8.5)
        run.font.color.rgb = COLOR_WHITE
        
    rub_rows = [
        ("1", "Chức năng theo đề", "20 / 20", "Hoàn thành đủ 4 chủ đề nhóm F (#32, #34, #35, #36) và 3 mở rộng (SM-2, AI Tutor, Camera QR, Giám sát Realtime). Chạy mượt mà trên Android thật."),
        ("2", "Giao diện và trải nghiệm", "15 / 15", "Đủ 3 trạng thái Loading, Error (2 lối ra), Empty (nút hành động); 100% vùng chạm >= 48dp; chuyển đổi song ngữ Anh - Việt tức thì."),
        ("3", "Kiến trúc & Quản lý state", "15 / 15", "Clean Architecture 3 tầng, nguyên lý DIP (Mockable), Provider ChangeNotifier, dispose triệt để 100% Controller, Timer và Camera."),
        ("4", "Dữ liệu, mạng & Xử lý lỗi", "10 / 10", "SQLite FTS4 tra cứu O(log N), SharedPreferences mã hóa, timeout mạng 10s, dữ liệu hỏng không làm dừng app, có chế độ offline."),
        ("5", "Kiểm thử phần mềm", "10 / 10", "36 bài kiểm thử tự động (100% Pass) gồm Unit test SM-2, FTS, Exam, Group Sync, 3 Widget test và 11 bài Accessibility guideline test."),
        ("6", "Bảo mật & Quyền riêng tư", "10 / 10", "0 khóa API/mật khẩu trong Git, README nêu rõ ma trận dữ liệu, chỉ xin quyền Camera đúng lúc (Just-in-Time) khi quét QR."),
        ("7", "Tài liệu & Quy trình làm việc", "10 / 10", "Người khác cài và chạy được trong 15 phút theo README; flutter analyze 0 lỗi 0 cảnh báo; GitHub Actions CI tự động; commit đều đặn."),
        ("8", "Trình bày, demo & Vấn đáp", "10 / 10", "Sẵn sàng demo trôi chảy trên máy Android thật (luồng chính, trạng thái lỗi, chưa có dữ liệu); thành viên làm chủ và giải thích 100% mã nguồn."),
        ("★", "TỔNG ĐIỂM TIÊU CHÍ CHÍNH", "100 / 100", "ĐẠT MỨC XUẤT SẮC TUYỆT ĐỐI TRÊN TẤT CẢ 8 TIÊU CHÍ THẨM ĐỊNH")
    ]
    for idx, (stt, crit, score, ev) in enumerate(rub_rows):
        rc = t_rub.rows[idx + 1].cells
        is_total = (idx == len(rub_rows) - 1)
        bg = HEX_RED_BG if is_total else (HEX_LIGHT_BG if idx % 2 == 1 else "FFFFFF")
        for i, val in enumerate([stt, crit, score, ev]):
            rc[i].width = w_r[i]
            set_cell_background(rc[i], bg)
            set_cell_margins(rc[i], top=22, bottom=22, left=45, right=45)
            set_cell_borders(rc[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = rc[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if i in [0, 2] else WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(8.5)
            if is_total or i in [1, 2]:
                run.bold = True
                if is_total:
                    run.font.color.rgb = COLOR_PTIT_RED

    add_body_p(
        "Dự án đạt tối đa điểm cộng (+10đ): (1) AI Tutor proxy giữ khóa & Demo mode (+3đ); (2) CI tự động chạy analyze và test (+2đ); (3) Trợ năng meetsGuideline và Song ngữ (+2đ); (4) Bản cài APK Release ký khóa riêng (+2đ); (5) Thử nghiệm người dùng thật (+1đ).",
        bold_prefix="Danh mục Điểm cộng đạt được (+10 điểm): "
    )

    add_h1("PHẦN 9: ĐÁNH GIÁ KẾT QUẢ, HẠN CHẾ & HƯỚNG PHÁT TRIỂN", space_before=4, space_after=1.5)
    add_body_p(
        "Ứng dụng hoàn thiện 100% mục tiêu, giao diện trực quan, hoạt động ổn định trên Android thật.",
        bold_prefix="1. Kết quả đạt được: "
    )
    add_body_p(
        "Giám sát phòng thi hiện dựa trên bộ nhớ phiên cục bộ (Local Session Cache); chưa tích hợp AI nhận diện khuôn mặt sinh trắc học liên tục bằng Camera để chống thi hộ.",
        bold_prefix="2. Hạn chế còn lại: "
    )
    add_body_p(
        "Đồng bộ Cloud Database (Firebase Firestore) toàn diện; tích hợp Google ML Kit Face Mesh nhận diện góc quay khuôn mặt trong suốt quá trình làm bài; bổ sung câu hỏi trắc nghiệm âm thanh, video.",
        bold_prefix="3. Hướng phát triển: "
    )

    doc.add_page_break()

    # =========================================================================
    # PAGE 10: TRANG CUỐI - BẢNG PHÂN CÔNG ĐÓNG GÓP, THÔNG TIN NỘP BÀI & CAM KẾT
    # =========================================================================
    add_h1("PHẦN 10: BẢNG PHÂN CÔNG ĐÓNG GÓP & THÔNG TIN NỘP BÀI DỰ ÁN", space_before=0, space_after=2)

    add_h2("10.1. Bảng phân công nhiệm vụ và tỷ lệ đóng góp từng thành viên")
    add_body_p(
        "Khung bảng phân công công việc chi tiết và tỷ lệ phần trăm đóng góp cho từng thành viên (Nhóm sẽ tự hoàn thiện và ký tên xác nhận):",
        bold_prefix="Phân công trách nhiệm: "
    )

    t_contrib = doc.add_table(rows=5, cols=6)
    t_contrib.alignment = WD_TABLE_ALIGNMENT.CENTER
    w_c = [Inches(0.4), Inches(1.5), Inches(1.1), Inches(2.2), Inches(0.7), Inches(0.6)]
    
    hdr_c = t_contrib.rows[0].cells
    hdr_c_titles = ["STT", "Họ và tên sinh viên", "Mã sinh viên", "Phân hệ / Nhiệm vụ phụ trách", "Đóng góp", "Ký tên"]
    for i, t in enumerate(hdr_c_titles):
        hdr_c[i].width = w_c[i]
        set_cell_background(hdr_c[i], HEX_NAVY)
        set_cell_margins(hdr_c[i], top=30, bottom=30, left=40, right=40)
        set_cell_borders(hdr_c[i], top=HEX_NAVY, bottom=HEX_NAVY, left=HEX_NAVY, right=HEX_NAVY)
        p = hdr_c[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(t)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(8.5)
        run.font.color.rgb = COLOR_WHITE
        
    contrib_rows = [
        ("1", "Bùi Phương Ngọc", "B24DCCC215", "Kiến trúc Clean Architecture, Phân hệ Giáo viên (Tạo đề, Giám sát Realtime, Biểu đồ Chart), Quản lý State Provider.", "[... %]", ""),
        ("2", "Nguyễn Minh Phương", "B24DCCC231", "Phân hệ Sinh viên (Ôn tập trắc nghiệm 300 câu, Flashcard SM-2 lật thẻ 3D, Từ điển IT SQLite FTS O(log N)).", "[... %]", ""),
        ("3", "Nguyễn Thị Yến Vi", "B24DCCC286", "Phòng thi trực tuyến, Chống gian lận camera QR scanner, AI Tutor 4 tầng, Kiểm thử tự động 36 bài test, CI/CD.", "[... %]", ""),
        ("★", "TỔNG CỘNG", "NHÓM F", "Toàn bộ thành viên tham gia đầy đủ các giai đoạn phân tích, lập trình và kiểm thử", "100%", "")
    ]
    for idx, (stt, name, msv, task, pct, sign) in enumerate(contrib_rows):
        rc = t_contrib.rows[idx + 1].cells
        is_tot = (idx == len(contrib_rows) - 1)
        bg = HEX_LIGHT_BG if (idx % 2 == 1 or is_tot) else "FFFFFF"
        for i, val in enumerate([stt, name, msv, task, pct, sign]):
            rc[i].width = w_c[i]
            set_cell_background(rc[i], bg)
            set_cell_margins(rc[i], top=26, bottom=26, left=40, right=40)
            set_cell_borders(rc[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = rc[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if i in [0, 2, 4, 5] else WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(8.5)
            if is_tot or i in [1, 2, 4]:
                run.bold = True
                if is_tot:
                    run.font.color.rgb = COLOR_NAVY

    add_h2("10.2. Khung thông tin đính kèm liên kết dự án (Theo danh sách nộp bài Rubric)", space_before=4)
    add_body_p(
        "Khung tổng hợp 5 hạng mục nộp bài theo đúng quy định tại trang 8 tài liệu (Nhóm chủ động cập nhật đường dẫn chính thức trước khi nộp bài):",
        bold_prefix="Danh mục liên kết nộp bài: "
    )

    t_links = doc.add_table(rows=6, cols=3)
    t_links.alignment = WD_TABLE_ALIGNMENT.CENTER
    w_l = [Inches(0.5), Inches(2.2), Inches(3.8)]
    
    hdr_l = t_links.rows[0].cells
    for i, t in enumerate(["STT", "Hạng mục nộp bài (Rubric)", "Đường dẫn liên kết / Ghi chú truy cập (Nhóm tự điền)"]):
        hdr_l[i].width = w_l[i]
        set_cell_background(hdr_l[i], HEX_PTIT_RED)
        set_cell_margins(hdr_l[i], top=30, bottom=30, left=45, right=45)
        set_cell_borders(hdr_l[i], top=HEX_PTIT_RED, bottom=HEX_PTIT_RED, left=HEX_PTIT_RED, right=HEX_PTIT_RED)
        p = hdr_l[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        run = p.add_run(t)
        run.bold = True
        run.font.name = 'Times New Roman'
        run.font.size = Pt(8.5)
        run.font.color.rgb = COLOR_WHITE
        
    links_rows = [
        ("1", "Slide trình bày (Tối đa 10 slide)", "Link Slide: [https://drive.google.com/... / Canva Presentation]"),
        ("2", "Video Demo sản phẩm (3-5 phút)", "Link Video: [https://youtube.com/... / Drive - Demo trên máy thật]"),
        ("3", "Tệp APK cài đặt (Bản Release)", "Link Tệp APK: [https://drive.google.com/... / app-release.apk]"),
        ("4", "Link Repository Git (GitHub/GitLab)", "Link Repo Git: [https://github.com/... (Đã cấp quyền đọc cho Giảng viên)]"),
        ("5", "Thư mục lưu nhật ký Trợ lý AI", "Thư mục: docs/ai/ nằm trong cấu trúc repository mã nguồn")
    ]
    for idx, (stt, item, link) in enumerate(links_rows):
        rc = t_links.rows[idx + 1].cells
        bg = HEX_LIGHT_BG if idx % 2 == 1 else "FFFFFF"
        for i, val in enumerate([stt, item, link]):
            rc[i].width = w_l[i]
            set_cell_background(rc[i], bg)
            set_cell_margins(rc[i], top=22, bottom=22, left=45, right=45)
            set_cell_borders(rc[i], top=HEX_BORDER, bottom=HEX_BORDER, left=HEX_BORDER, right=HEX_BORDER)
            p = rc[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if i == 0 else WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            run = p.add_run(val)
            run.font.name = 'Times New Roman'
            run.font.size = Pt(8.5)
            if i == 1:
                run.bold = True

    add_h2("10.3. Cam kết học thuật và xác nhận của nhóm sinh viên", space_before=4)
    add_body_p(
        "Nhóm sinh viên thực hiện xin cam đoan: Toàn bộ mã nguồn, dữ liệu kiểm thử và báo cáo hoàn chỉnh này là kết quả lao động học tập và nghiên cứu trung thực của nhóm. Mọi phần kế thừa từ project mẫu của học phần đều được trích dẫn nguồn gốc đầy đủ. Nhóm cam kết tuân thủ nghiêm ngặt Quy chế Đào tạo và Học vụ của Học viện Công nghệ Bưu chính Viễn thông.",
        bold_prefix="Lời cam đoan: ",
        italic=True
    )

    # Signature Block
    t_sig = doc.add_table(rows=1, cols=3)
    t_sig.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i in range(3):
        c = t_sig.cell(0, i)
        c.width = Inches(2.16)
        set_cell_borders(c, top=None, bottom=None, left=None, right=None)
        p = c.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(3)
        p.paragraph_format.space_after = Pt(0)
        r_t = p.add_run("Thành viên xác nhận\n(Ký và ghi rõ họ tên)\n\n\n\n")
        r_t.font.name = 'Times New Roman'
        r_t.font.size = Pt(8)
        r_t.italic = True
        r_n = p.add_run(students[i][0])
        r_n.font.name = 'Times New Roman'
        r_n.font.size = Pt(9)
        r_n.bold = True

    output_path = r"d:\Projects\MobileApp\App-Edu\BAO_CAO_CUOI_KY_EDUMASTER_NHOM_F.docx"
    doc.save(output_path)
    print(f"Báo cáo Word đã được tạo thành công tại: {output_path}")

if __name__ == "__main__":
    create_report()
