local Rect = require 'pud.kit.Rect'

context('Rect', function()
	context('When instantiated with no arguments', function()
		local r = Rect()
		test('should exist', function()
			assert_not_nil(r)
			assert_true(r:is_a(Rect))
		end)
		test('should have correct default x and y position', function()
			assert_equal(r:getX(), 0)
			assert_equal(r:getY(), 0)
		end)
		test('should have correct default width and height', function()
			assert_equal(r:getWidth(), 0)
			assert_equal(r:getHeight(), 0)
		end)
		test('should have correct default bounding box', function()
			local x1, y1, x2, y2 = r:getBBox()
			assert_equal(x1, 0)
			assert_equal(y1, 0)
			assert_equal(x2, 0)
			assert_equal(y2, 0)
		end)
		test('should have correct default center coordinates', function()
			local cx, cy = r:getCenter()
			assert_equal(cx, 0)
			assert_equal(cy, 0)
		end)
		test('should have correct default rounded center coordinates', function()
			local cx, cy = r:getCenter(true)
			assert_equal(cx, 0)
			assert_equal(cy, 0)
		end)
		test('should have correct default __tostring value', function()
			assert_equal(tostring(r), '(0,0) 0x0')
		end)
	end)

	context('When instantiated with arguments', function()
		local r = Rect(3, 15, 21, 50)
		test('should exist', function()
			assert_not_nil(r)
			assert_true(r:is_a(Rect))
		end)
		test('should have correct x and y position', function()
			assert_equal(r:getX(), 3)
			assert_equal(r:getY(), 15)
		end)
		test('should have correct width and height', function()
			assert_equal(r:getWidth(), 21)
			assert_equal(r:getHeight(), 50)
		end)
		test('should have correct bounding box', function()
			local x1, y1, x2, y2 = r:getBBox()
			assert_equal(x1, 3)
			assert_equal(y1, 15)
			assert_equal(x2, 3+21)
			assert_equal(y2, 15+50)
		end)
		test('should have correct center coordinates', function()
			local cx, cy = r:getCenter()
			assert_equal(cx, 3+21/2)
			assert_equal(cy, 15+50/2)
		end)
		test('should have correct rounded center coordinates', function()
			local cx, cy = r:getCenter(true)
			assert_equal(cx, 3+math.floor(21/2 + 0.5))
			assert_equal(cy, 15+math.floor(50/2 + 0.5))
		end)
		test('should have correct __tostring value', function()
			assert_equal(tostring(r), '(3,15) 21x50')
		end)
	end)

	context('When setting position and size values', function()
		local r = Rect()
		r:setPosition(3, 15)
		r:setSize(21, 50)

		test('should have correct x and y position', function()
			assert_equal(r:getX(), 3)
			assert_equal(r:getY(), 15)
		end)
		test('should have correct width and height', function()
			assert_equal(r:getWidth(), 21)
			assert_equal(r:getHeight(), 50)
		end)
		test('should have correct bounding box', function()
			local x1, y1, x2, y2 = r:getBBox()
			assert_equal(x1, 3)
			assert_equal(y1, 15)
			assert_equal(x2, 3+21)
			assert_equal(y2, 15+50)
		end)
		test('should have correct center coordinates', function()
			local cx, cy = r:getCenter()
			assert_equal(cx, 3+21/2)
			assert_equal(cy, 15+50/2)
		end)
		test('should have correct rounded center coordinates', function()
			local cx, cy = r:getCenter(true)
			assert_equal(cx, 3+math.floor(21/2 + 0.5))
			assert_equal(cy, 15+math.floor(50/2 + 0.5))
		end)
		test('should have correct __tostring value', function()
			assert_equal(tostring(r), '(3,15) 21x50')
		end)
	end)

	context('When setting center position', function()
		context('without rounding', function()
			local r = Rect()
			r:setSize(21, 50)
			r:setCenter(13, 40)

			test('should have correct size', function()
				assert_equal(r:getWidth(), 21)
				assert_equal(r:getHeight(), 50)
			end)
			test('should have correct x and y position', function()
				assert_equal(r:getX(), 2.5)
				assert_equal(r:getY(), 15)
			end)
			test('should have correct bounding box', function()
				local x1, y1, x2, y2 = r:getBBox()
				local w, h = r:getSize()
				assert_equal(x1, 2.5)
				assert_equal(y1, 15)
				assert_equal(x2, 2.5+21)
				assert_equal(y2, 15+50)
				assert_equal(x2-x1, w)
				assert_equal(y2-y1, h)
			end)
			test('should have correct center coordinates', function()
				local cx, cy = r:getCenter()
				assert_equal(cx, 2.5+21/2)
				assert_equal(cy, 15+50/2)
			end)
			test('should have correct rounded center coordinates', function()
				local cx, cy = r:getCenter(true)
				assert_equal(cx, 2.5+math.floor(21/2 + 0.5))
				assert_equal(cy, 15+math.floor(50/2 + 0.5))
			end)
		end)

		context('with rounding', function()
			local r = Rect()
			r:setSize(21, 50)
			r:setCenter(13, 40, true)

			test('should have correct size', function()
				assert_equal(r:getWidth(), 21)
				assert_equal(r:getHeight(), 50)
			end)
			test('should have correct x and y position', function()
				assert_equal(r:getX(), 2)
				assert_equal(r:getY(), 15)
			end)
			test('should have correct bounding box', function()
				local x1, y1, x2, y2 = r:getBBox()
				local w, h = r:getSize()
				assert_equal(x1, 2)
				assert_equal(y1, 15)
				assert_equal(x2, 2+21)
				assert_equal(y2, 15+50)
				assert_equal(x2-x1, w)
				assert_equal(y2-y1, h)
			end)
			test('should have correct center coordinates', function()
				local cx, cy = r:getCenter()
				assert_equal(cx, 2+21/2)
				assert_equal(cy, 15+50/2)
			end)
			test('should have correct rounded center coordinates', function()
				local cx, cy = r:getCenter(true)
				assert_equal(cx, 2+math.floor(21/2 + 0.5))
				assert_equal(cy, 15+math.floor(50/2 + 0.5))
			end)
		end)
	end)
end)
