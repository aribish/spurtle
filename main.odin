package main

// i probably should have used the string library :(
// i bet this is way more efficient though

import "core:fmt"
import "core:os"
import rl "vendor:raylib"

FPS :: 60;
WIN_MIN_WIDTH :: 640;
WIN_MIN_HEIGHT :: 640;
FONT_SIZE :: 32;
CELL_SIZE :: 40;
CELL_SPACING :: 10;

START_TEXT :: "press space to start new game";
QUIT_TEXT :: "press esc to quit game";

LETTER_INFO :: enum u8 {
	NONE,
	ABSENT, // or already present
	PRESENT_SAME_INDEX,
	PRESENT_DIFFERENT_INDEX
};

GAME_STATE :: enum u8 {
	NOT_STARTED,
	STARTED,
	WIN,
	LOSE
};

font : rl.Font;
charSize : rl.Vector2;
wordList : [dynamic][]u8;
word : [7]u8; // the word to guess
guesses : [7][7]u8;
guessInfo : [7][6]LETTER_INFO; // for keeping track of colors
currentGuess: int; // index of current guess
wordIndex: int; // index of char in current guess
gameState := GAME_STATE.NOT_STARTED; // per-round

// returns the difference of the first different character between the current guess and word at wordIndex
compareWords :: proc(wordIndex: int) -> int {
	for i in 0..<6 {
		dif := int(guesses[currentGuess][i]) - int(wordList[wordIndex][i]);
		if dif != 0 {
			return dif;
		}
	}

	return 0
}

wordExists :: proc() -> bool {
	low := 0;
	high := len(wordList) - 2;

	for low <= high {
		i := low + (high - low) / 2;
		res := compareWords(i);

		if res < 0 {
			high = i - 1;
		}
		else if res > 0 {
			low = i + 1;
		}
		else {
			return true;
		}

	}

	return false
}

update :: proc(winWidth, winHeight: f32) {
	if gameState != GAME_STATE.STARTED {
		if rl.IsKeyReleased(rl.KeyboardKey.SPACE) {
			gameState = GAME_STATE.STARTED;
			
			// generate new word
			newWordIndex := rl.GetRandomValue(0, i32(len(wordList)) - 1);

			for i in 0..<6 {
				word[i] = wordList[newWordIndex][i];
			}

			// reset guess info
			for i in 0..<7 {
				for j in 0..<6 {
					guessInfo[i][j] = LETTER_INFO.NONE;
				}
			}

			// reset guesses
			for i in 0..<7 {
				for j in 0..<7 {
					guesses[i][j] = 0;
				}
			}

			// reset indices
			currentGuess = 0;
			wordIndex = 0;
		}
	}
	else {
		key := u8(rl.GetCharPressed());

		if ((key >= 65 && key <= 90) || (key >= 97 && key <= 122)) && wordIndex < 6 {
			guesses[currentGuess][wordIndex] = key;
			wordIndex += 1;
		}
		else if rl.IsKeyPressed(rl.KeyboardKey.ENTER) && wordIndex >= 6 && wordExists() {
			wordIndex = 0;
			correctWord := true;

			// get word info
			for i in 0..<6 {
				for j in 0..<6 {
					if guesses[currentGuess][i] == word[j] {
						if i == j {
							guessInfo[currentGuess][i] = LETTER_INFO.PRESENT_SAME_INDEX;
							break;
						}
						else {
							guessInfo[currentGuess][i] = LETTER_INFO.PRESENT_DIFFERENT_INDEX;
						}
					}
					else {
						if i == j {
							correctWord = false;
						}
						if j == 5 && guessInfo[currentGuess][i] == LETTER_INFO.NONE { 
							guessInfo[currentGuess][i] = LETTER_INFO.ABSENT;
						}
					}
				}
			}

			// clean up repeats
			for i in 0..<6 {
				numRepeatedInWord := 0;
				numRepeatedInGuess := 0;
				numCorrect := 0;

				if guessInfo[currentGuess][i] == LETTER_INFO.ABSENT {
					continue
				}

				for j in (i + 1)..<6 {
					if word[i] == word[j] {
						numRepeatedInWord += 1;
					}

					if guesses[currentGuess][i] == guesses[currentGuess][j] {
						numRepeatedInGuess += 1;

						if guessInfo[currentGuess][j] == LETTER_INFO.PRESENT_SAME_INDEX {
							numCorrect += 1;
						}
					}
				}

				if numRepeatedInWord == numCorrect && numRepeatedInGuess > numCorrect {
					for j in i..<6 {
						if guesses[currentGuess][i] == guesses[currentGuess][j] && guessInfo[currentGuess][j] == LETTER_INFO.PRESENT_DIFFERENT_INDEX {
							guessInfo[currentGuess][j] = LETTER_INFO.ABSENT;
						}
					}
				}
			}

			currentGuess += 1;

			if correctWord {
				gameState = GAME_STATE.WIN;
			}
			else if currentGuess >= 7 {
				gameState = GAME_STATE.LOSE;
			}
		}
		else if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) && wordIndex > 0 {
			wordIndex -= 1;
			guesses[currentGuess][wordIndex] = 0;
		}
	}
}

draw :: proc(winWidth, winHeight: f32) {
	rl.ClearBackground(rl.WHITE);
	rl.DrawTextEx(font, "spurtle!", {(winWidth - charSize.x * 8) / 2, charSize.y / 2}, FONT_SIZE, 0, rl.BLACK);

	if gameState != GAME_STATE.STARTED {
		rl.DrawTextEx(font, START_TEXT, {(winWidth - charSize.x * len(START_TEXT)) / 2, winHeight - charSize.y * 2}, FONT_SIZE, 0, rl.BLACK);
	}
	
	if gameState == GAME_STATE.STARTED {
		startPos := rl.Vector2{(winWidth - (CELL_SIZE + CELL_SPACING) * 6 + CELL_SPACING) / 2, 
		(winHeight - (CELL_SIZE + CELL_SPACING) * 6 + CELL_SPACING) / 2};

		for i in 0..<7 {
			for j in 0..<6 {
				color : rl.Color;

				if i == currentGuess && j == wordIndex {
					color = rl.DARKGRAY;
				}
				else if guessInfo[i][j] == LETTER_INFO.ABSENT {
					color = rl.DARKGRAY;
				}
				else if guessInfo[i][j] == LETTER_INFO.PRESENT_DIFFERENT_INDEX {
					color = rl.YELLOW;
				}
				else if guessInfo[i][j] == LETTER_INFO.PRESENT_SAME_INDEX {
					color = rl.GREEN;
				}
				else {
					color = rl.LIGHTGRAY;
				}
				
				rl.DrawRectangleV({startPos.x + f32(j * (CELL_SIZE + CELL_SPACING)), startPos.y + f32(i * (CELL_SIZE + CELL_SPACING))}, 
				{CELL_SIZE, CELL_SIZE}, color);
			}

			// draw whole guess string
			if guesses[i][0] != 0 {
				rl.DrawTextEx(font, cstring(raw_data(&guesses[i])),
				{startPos.x + (CELL_SIZE - charSize.x) / 2, startPos.y + f32(i * (CELL_SIZE + CELL_SPACING)) + (CELL_SIZE - charSize.y) / 2},
				FONT_SIZE, CELL_SIZE - charSize.x + CELL_SPACING, rl.BLACK);
			}
		}
	}
	else if gameState == GAME_STATE.WIN {
		rl.DrawTextEx(font, "you win!", {(winWidth - charSize.x * 8) / 2, charSize.y * 2}, FONT_SIZE, 0, rl.GREEN);
	}
	else if gameState == GAME_STATE.LOSE {
		rl.DrawTextEx(font, "you lose!", {(winWidth - charSize.x * 9) / 2, charSize.y * 2}, FONT_SIZE, 0, rl.RED);
		rl.DrawTextEx(font, cstring(raw_data(&word)), {(winWidth - charSize.x * 6) / 2, (winHeight - charSize.y) / 2}, FONT_SIZE, 0, rl.DARKGRAY);
	}

	rl.DrawTextEx(font, QUIT_TEXT, {(winWidth - charSize.x * len(QUIT_TEXT)) / 2, winHeight - charSize.y}, FONT_SIZE, 0, rl.BLACK);
}

initwordList :: proc() {
	rawWords, _ := os.read_entire_file_from_filename("words.txt");
	i := 2;

	for i + 6 < len(rawWords) {
		append(&wordList, rawWords[i:(i+6)]);
		i = i + 8;
	}

}

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE});
	rl.InitWindow(WIN_MIN_WIDTH, WIN_MIN_HEIGHT, "spurtle!");
	defer rl.CloseWindow();

	rl.SetWindowMinSize(WIN_MIN_WIDTH, WIN_MIN_HEIGHT);
	rl.SetExitKey(rl.KeyboardKey.ESCAPE);
	rl.SetTargetFPS(FPS);

	// font
	font = rl.LoadFont("font/RubikMonoOne-Regular.ttf");
	defer rl.UnloadFont(font);

	// dimensions of shit
	charSize = rl.MeasureTextEx(font, "#", FONT_SIZE, 0);
	winWidth := f32(rl.GetRenderWidth());
	winHeight := f32(rl.GetRenderHeight());

	// words
	initwordList();
	defer delete(wordList);

	// rand
	rl.SetRandomSeed(u32(rl.GetTime() * 1000));
	
	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			winWidth = f32(rl.GetRenderWidth());
			winHeight = f32(rl.GetRenderHeight());
		}
		
		update(winWidth, winHeight);

		rl.BeginDrawing();
		draw(winWidth, winHeight);
		rl.EndDrawing(); // this automatically calls PollInputEvents!!!!!!!!!!!!!!!!
	}
}
