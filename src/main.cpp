#include <bx/uint32_t.h>
#include "common.h"
#include "bgfx_utils.h"
#include "entry/cmd.h"

#define IMGUI_DEFINE_MATH_OPERATORS
#include "imgui/imgui.h" 
#include "ocornut-imgui/imgui_internal.h"

class mainapp : public entry::AppI
{
public:
	void init(int _argc, char** _argv) override;
	virtual int shutdown() override;
	bool update() override;
	void DrawWindow();

	uint32_t m_width;
	uint32_t m_height;
	uint32_t m_debug;
	uint32_t m_reset;
	entry::MouseState m_mouseState;
	ImVec2 scrolling;
};

ENTRY_IMPLEMENT_MAIN(mainapp);

void displayMainMenu()
{
	if (ImGui::BeginMainMenuBar())
	{
		if (ImGui::BeginMenu(ICON_FA_FILE " Files"))
		{
			if (ImGui::MenuItem("New", "")) {}
			if (ImGui::MenuItem("Open", "")) {}
			if (ImGui::MenuItem("Save", "")) {}
			ImGui::Separator();
			if (ImGui::MenuItem("Exit", "Alt-F4")) {}
			ImGui::EndMenu();
		}
		ImGui::EndMainMenuBar();
	}
}

void mainapp::init(int _argc, char** _argv)
{
	Args args(_argc, _argv);

	m_width = 1280;
	m_height = 720;
	m_debug = BGFX_DEBUG_NONE;
	m_reset = BGFX_RESET_NONE;

	// Disable commands from BGFX
	cmdShutdown();
	cmdInit();

	bgfx::init(args.m_type, args.m_pciId);
	bgfx::reset(m_width, m_height, m_reset);

	// Enable debug text.
	bgfx::setDebug(m_debug);

	// Set view 0 clear state.
	bgfx::setViewClear(0
		, BGFX_CLEAR_COLOR | BGFX_CLEAR_DEPTH
		, 0x000000ff
		, 1.0f
		, 0
	);
	imguiCreate();

	scrolling = ImVec2(0.0f, 0.0f);
}

int mainapp::shutdown()
{
	// Cleanup.
	imguiDestroy();

	// Shutdown bgfx.
	bgfx::shutdown();

	return 0;
}

void mainapp::DrawWindow()
{
	ImGui::SetNextWindowPos(ImVec2(0, 24));
	ImGui::SetNextWindowSize(ImVec2(float(m_width), float(m_height - 24)));
	if (!ImGui::Begin("Window1", nullptr, ImVec2(float(m_width), float(m_height - 24)), 1.0f, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoSavedSettings | ImGuiWindowFlags_NoCollapse | ImGuiWindowFlags_NoScrollbar))
	{
		ImGui::End();
		return;
	}
	
	const ImGuiIO io = ImGui::GetIO();

	const bool isMouseDraggingForScrolling = ImGui::IsMouseDragging(2, 0.0f);

	ImGui::BeginChild("GraphNodeChildWindow", ImVec2(0, 0), false);

	ImGui::PushStyleColor(ImGuiCol_ChildWindowBg, ImColor(60, 60, 70, 200));
	ImGui::BeginChild("scrolling_region", ImVec2(0, 0), true, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoMove | ImGuiWindowFlags_NoScrollWithMouse);

	// fixes zooming just a bit
	ImDrawList* draw_list = ImGui::GetWindowDrawList();
	ImVec2 canvasSize = ImGui::GetWindowSize();
	ImVec2 offset = ImGui::GetCursorPos() - scrolling;
	ImVec2 win_pos = ImGui::GetCursorScreenPos();


	// Display grid
	const ImU32& GRID_COLOR = ImColor(200, 200, 200, 40);
	const float& GRID_SZ = 64.f;
	const float grid_Line_width = ImGui::GetCurrentWindow()->FontWindowScale * 1.f;
	for (float x = fmodf(offset.x, GRID_SZ); x < canvasSize.x; x += GRID_SZ)
		draw_list->AddLine(ImVec2(x, 0.0f) + win_pos, ImVec2(x, canvasSize.y) + win_pos, GRID_COLOR, grid_Line_width);
	for (float y = fmodf(offset.y, GRID_SZ); y < canvasSize.y; y += GRID_SZ)
		draw_list->AddLine(ImVec2(0.0f, y) + win_pos, ImVec2(canvasSize.x, y) + win_pos, GRID_COLOR, grid_Line_width);

	// Scrolling
	if (isMouseDraggingForScrolling  && (ImGui::IsWindowHovered() || ImGui::IsWindowFocused() || ImGui::IsRootWindowFocused())) 
		scrolling = scrolling - io.MouseDelta;

	ImGui::EndChild();
	ImGui::PopStyleColor();
	ImGui::EndChild();
	ImGui::End();
}

bool mainapp::update()
{
	if (!entry::processEvents(m_width, m_height, m_debug, m_reset, &m_mouseState))
	{
		bgfx::setViewRect(0, 0, 0, uint16_t(m_width), uint16_t(m_height));
		bgfx::touch(0);

		imguiBeginFrame(m_mouseState.m_mx
			, m_mouseState.m_my
			, (m_mouseState.m_buttons[entry::MouseButton::Left] ? IMGUI_MBUT_LEFT : 0)
			| (m_mouseState.m_buttons[entry::MouseButton::Right] ? IMGUI_MBUT_RIGHT : 0)
			| (m_mouseState.m_buttons[entry::MouseButton::Middle] ? IMGUI_MBUT_MIDDLE : 0)
			, m_mouseState.m_mz
			, m_width
			, m_height
		);

		displayMainMenu();
		DrawWindow();
		imguiEndFrame();
		bgfx::frame();
		return true;
	}

	return false;
}
