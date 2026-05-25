import XCTest

@MainActor
final class FocusFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Тест 1: Добавление задачи

    /// Открывает форму, вводит название, сохраняет.
    /// Ожидаемый результат: задача появляется в списке.
    func testAddTask_appearsInList() throws {
        app.buttons["addTaskButton"].tap()

        let titleField = app.textFields["titleField"]
        XCTAssertTrue(
            titleField.waitForExistence(timeout: 2),
            "Форма добавления должна появиться после нажатия «+»"
        )

        titleField.tap()
        titleField.typeText("Купить молоко")
        app.buttons["saveButton"].tap()

        XCTAssertTrue(
            app.staticTexts["Купить молоко"].waitForExistence(timeout: 3),
            "Задача должна появиться в списке после сохранения"
        )
    }

    // MARK: - Тест 2: Удаление свайпом

    /// Добавляет задачу, свайпает карточку влево, нажимает «Удалить».
    /// Ожидаемый результат: задача исчезает из списка.
    func testDeleteTask_swipeLeft_removesFromList() throws {
        addTask("Задача для удаления")

        let card = app.otherElements["taskCard"].firstMatch
        XCTAssertTrue(
            card.waitForExistence(timeout: 2),
            "Карточка задачи должна отображаться"
        )

        // Координатный свайп: от 90 % ширины к 15 % — достаточно для открытия кнопки.
        // allowsFullSwipe отключён в представлении, поэтому кнопка точно появится.
        let startCoord = card.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
        let endCoord   = card.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5))
        startCoord.press(forDuration: 0.1, thenDragTo: endCoord)

        // Кнопка ищется через descendants(matching: .any), чтобы не зависеть
        // от того, как SwiftUI классифицирует элемент вне List-контекста.
        let deleteButton = app.descendants(matching: .any)
            .matching(identifier: "deleteButton")
            .firstMatch
        XCTAssertTrue(
            deleteButton.waitForExistence(timeout: 2),
            "Кнопка «Удалить» должна появиться после свайпа"
        )
        deleteButton.tap()

        XCTAssertFalse(
            app.staticTexts["Задача для удаления"].waitForExistence(timeout: 2),
            "Удалённая задача не должна отображаться в списке"
        )
    }

    // MARK: - Тест 3: Отметка выполнения

    /// Добавляет задачу, нажимает кнопку галочки.
    /// Ожидаемый результат: accessibilityValue меняется «pending» → «completed».
    func testToggleCompletion_marksTaskDone() throws {
        addTask("Выполнить эту задачу")

        // descendants(matching: .any) ищет по всем типам элементов,
        // не зависит от того, как SwiftUI представляет Button в accessibility-дереве
        let toggle = app.descendants(matching: .any)
            .matching(identifier: "toggleComplete")
            .firstMatch

        XCTAssertTrue(
            toggle.waitForExistence(timeout: 2),
            "Кнопка завершения задачи должна существовать"
        )
        XCTAssertEqual(
            toggle.value as? String,
            "pending",
            "Новая задача должна иметь статус «pending»"
        )

        toggle.tap()

        let completedPredicate = NSPredicate(format: "value == 'completed'")
        let completedExpectation = XCTNSPredicateExpectation(
            predicate: completedPredicate,
            object: toggle
        )
        wait(for: [completedExpectation], timeout: 2.0)

        XCTAssertEqual(
            toggle.value as? String,
            "completed",
            "После нажатия галочки задача должна иметь статус «completed»"
        )
    }

    // MARK: - Тест 4: Валидация пустого поля

    /// Открывает форму, не вводит название, нажимает «Сохранить».
    /// Ожидаемый результат: форма остаётся открытой.
    func testSave_withEmptyTitle_keepsSheetOpen() throws {
        app.buttons["addTaskButton"].tap()

        let titleField = app.textFields["titleField"]
        XCTAssertTrue(
            titleField.waitForExistence(timeout: 2),
            "Форма должна открыться"
        )

        app.buttons["saveButton"].tap()

        XCTAssertTrue(
            titleField.waitForExistence(timeout: 1.5),
            "Форма не должна закрываться при пустом поле названия"
        )
    }

    // MARK: - Вспомогательный метод

    private func addTask(_ title: String) {
        app.buttons["addTaskButton"].tap()
        let titleField = app.textFields["titleField"]
        _ = titleField.waitForExistence(timeout: 2)
        titleField.tap()
        titleField.typeText(title)
        app.buttons["saveButton"].tap()
        _ = app.staticTexts[title].waitForExistence(timeout: 3)
    }
}
